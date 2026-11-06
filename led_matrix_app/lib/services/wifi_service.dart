import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import '../models/board.dart';

class WifiService {
  static const MethodChannel _channel = MethodChannel('com.ledmatrix.wifi');

  /// Buộc Android định tuyến toàn bộ socket TCP qua card Wi-Fi (bỏ qua 4G di động)
  static Future<bool> bindCurrentWifi() async {
    try {
      final bool? res = await _channel.invokeMethod<bool>('bindCurrentWifi');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Mở bảng chọn Wi-Fi nhanh của hệ thống Android
  static Future<void> openWifiSettings() async {
    try {
      await _channel.invokeMethod('openWifiSettings');
    } catch (_) {}
  }

  /// Lấy SSID Wi-Fi mà điện thoại đang kết nối hiện tại
  static Future<String> getCurrentWifiSsid() async {
    try {
      final String? ssid =
          await _channel.invokeMethod<String>('getCurrentWifiSsid');
      return ssid ?? '';
    } catch (_) {
      return '';
    }
  }

  /// Tự động kết nối thiết bị Android vào Wi-Fi của card LED
  static Future<bool> connectToBoardWifi(String ssid, String password) async {
    try {
      await disconnectWifi(ssid);
      await Future.delayed(const Duration(milliseconds: 450));
      final bool? result = await _channel.invokeMethod<bool>('connectWifi', {
        'ssid': ssid,
        'password': password,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      print('WiFi Connection Error: ${e.message}');
      await bindCurrentWifi();
      return false;
    } catch (_) {
      await bindCurrentWifi();
      return false;
    }
  }

  /// Ngắt kết nối mạng tạm thời
  static Future<void> disconnectWifi(String ssid) async {
    try {
      await _channel.invokeMethod('disconnectWifi', {'ssid': ssid});
    } catch (_) {}
  }

  /// Bắn chuỗi 4 gói tin Huidu chuẩn (Cmd 0x13, 0x02, 0x03, 0x04) qua TCP 6101 có kiểm tra ACK
  static Future<bool> sendPacketsToBoard({
    required String ip,
    required int port,
    required List<Uint8List> packets,
    Function(String log)? onLog,
  }) async {
    await bindCurrentWifi();

    Socket? socket;
    try {
      onLog?.call('  [TCP] Đang mở kết nối tới $ip:$port...');
      try {
        socket = await Socket.connect(
          ip,
          port,
          timeout: const Duration(seconds: 4),
        );
      } catch (_) {
        // Thử bind lại Wi-Fi và kết nối lần 2 nếu DHCP vừa cấp IP xong
        await Future.delayed(const Duration(milliseconds: 800));
        await bindCurrentWifi();
        socket = await Socket.connect(
          ip,
          port,
          timeout: const Duration(seconds: 5),
        );
      }
      socket.setOption(SocketOption.tcpNoDelay, true);

      final incoming = <int>[];
      final sub = socket.listen(
        (data) => incoming.addAll(data),
        onError: (e) => print('Socket listen error: $e'),
      );

      int ackSuccessCount = 0;

      for (int i = 0; i < packets.length; i++) {
        final pkt = packets[i];
        final cmd = pkt[6];
        final cmdHex =
            '0x${cmd.toRadixString(16).padLeft(2, '0').toUpperCase()}';

        incoming.clear();
        onLog?.call(
          '  [GỬI] Gói tin $cmdHex (Seq ${i + 1}/${packets.length}, ${pkt.length}B)...',
        );
        socket.add(pkt);
        await socket.flush();

        // Chờ nhận phản hồi ACK (HR, tìm khung 0x48 0x52 có byte +20 == cmd)
        bool ackOk = false;
        int? errStatus;
        final sw = Stopwatch()..start();
        while (sw.elapsedMilliseconds < 3000) {
          if (incoming.length >= 22) {
            for (int idx = 0; idx <= incoming.length - 22; idx++) {
              if (incoming[idx] == 0x48 && incoming[idx + 1] == 0x52) {
                final replyCmd = incoming[idx + 20];
                final status = incoming[idx + 21];
                if (replyCmd == cmd) {
                  if (status == 0x00) {
                    ackOk = true;
                  } else {
                    errStatus = status;
                  }
                  break;
                }
              }
            }
            if (ackOk || errStatus != null) break;
          }
          await Future.delayed(const Duration(milliseconds: 25));
        }

        if (ackOk) {
          ackSuccessCount++;
          onLog?.call('  [ACK OK] Card xác nhận gói $cmdHex thành công.');
        } else if (errStatus != null) {
          onLog?.call(
            '  [CẢNH BÁO] Card phản hồi mã 0x${errStatus.toRadixString(16).toUpperCase()} cho gói $cmdHex.',
          );
        } else {
          onLog?.call('  [ĐÃ PHÁT] Gói $cmdHex đã truyền xong.');
        }

        await Future.delayed(const Duration(milliseconds: 120));
      }

      await Future.delayed(const Duration(milliseconds: 300));
      await sub.cancel();
      return ackSuccessCount > 0;
    } catch (e) {
      onLog?.call('  [LỖI SOCKET] Không thể giao tiếp tại $ip:$port ($e)');
      return false;
    } finally {
      try {
        await socket?.close();
      } catch (_) {}
    }
  }

  /// Quy trình nạp một bảng đơn:
  /// 1. Kiểm tra Wi-Fi hiện tại -> nếu khác thì tự động yêu cầu kết nối
  /// 2. Ép bind Wi-Fi
  /// 3. Bắn 4 gói tin TCP
  static Future<bool> updateSingleBoard({
    required LedBoard board,
    required List<Uint8List> packets,
    required Function(String status) onStatus,
    bool allowFallbackToCurrentWifi = false,
  }) async {
    final currentSsid = await getCurrentWifiSsid();
    if (currentSsid.isNotEmpty &&
        currentSsid.toLowerCase() == board.ssid.toLowerCase()) {
      onStatus('  [WIFI] Đã kết nối sẵn đúng card: ${board.ssid}');
      await bindCurrentWifi();
    } else {
      onStatus(
        '  [WIFI] Đang chuyển sang Wi-Fi: ${board.ssid} (Bấm "Kết nối" nếu máy hỏi)...',
      );
      final connected = await connectToBoardWifi(board.ssid, board.password);
      await Future.delayed(const Duration(milliseconds: 900));

      if (!connected) {
        final afterSsid = await getCurrentWifiSsid();
        final isMatchedNow = afterSsid.isNotEmpty &&
            afterSsid.toLowerCase() == board.ssid.toLowerCase();

        if (!isMatchedNow) {
          if (!allowFallbackToCurrentWifi) {
            onStatus(
              '  [BỎ QUA] Chưa kết nối được Wi-Fi ${board.ssid}. Không gửi đè lên bảng khác!',
            );
            return false;
          }
          if (afterSsid.isNotEmpty &&
              afterSsid.toLowerCase().startsWith('wf2_') &&
              afterSsid.toLowerCase() != board.ssid.toLowerCase()) {
            onStatus(
              '  [CẢNH BÁO] Điện thoại đang bắt Wi-Fi "$afterSsid" khác với "${board.ssid}". Vui lòng chọn đúng Wi-Fi!',
            );
            return false;
          }
          onStatus(
            '  [WIFI] Đang thử truyền qua kết nối Wi-Fi hiện tại của máy...',
          );
        }
      }
    }

    final sent = await sendPacketsToBoard(
      ip: board.ip,
      port: board.port,
      packets: packets,
      onLog: onStatus,
    );

    if (sent) {
      onStatus('  [THÀNH CÔNG] ${board.name} (${board.ssid}) đã sáng chữ mới!');
    } else {
      onStatus('  [LỖI] Card ${board.ssid} không phản hồi tại ${board.ip}:${board.port}');
    }

    return sent;
  }
}
