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
      await Future.delayed(const Duration(milliseconds: 200));
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

  /// Bắn chuỗi 4 gói tin Huidu chuẩn (Cmd 0x13, 0x02, 0x03, 0x04) qua TCP 6101
  static Future<bool> sendPacketsToBoard({
    required String ip,
    required int port,
    required List<Uint8List> packets,
    Function(String log)? onLog,
  }) async {
    await bindCurrentWifi();

    Socket? socket;
    try {
      onLog?.call('  [TCP] Mở kết nối tới $ip:$port...');
      for (int attempt = 1; attempt <= 5; attempt++) {
        try {
          await bindCurrentWifi();
          socket = await Socket.connect(
            ip,
            port,
            timeout: const Duration(milliseconds: 2200),
          );
          break;
        } catch (e) {
          if (attempt == 5) rethrow;
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
      if (socket == null) {
        onLog?.call('  [LỖI SOCKET] Không thể mở cổng TCP $ip:$port.');
        return false;
      }
      socket.setOption(SocketOption.tcpNoDelay, true);

      final rxBuffer = <int>[];
      final sub = socket.listen(
        (data) => rxBuffer.addAll(data),
        onError: (e) => onLog?.call('  [LỖI SOCKET] $e'),
      );

      int ackSuccessCount = 0;
      int sentPackets = 0;
      bool cmd04AckOk = false;

      for (int i = 0; i < packets.length; i++) {
        final pkt = packets[i];
        final cmd = pkt[6];
        final cmdHex =
            '0x${cmd.toRadixString(16).padLeft(2, '0').toUpperCase()}';

        onLog?.call(
          '  [GỬI] Gói $cmdHex (Seq ${i + 1}/${packets.length}, ${pkt.length}B)...',
        );
        socket.add(pkt);
        await socket.flush();
        sentPackets++;

        // Chờ nhận phản hồi ACK chuẩn từ card HD-WF2:
        // Header 'HR' (28 bytes): byte 20 (0x14) = replyCmd, byte 21 (0x15) = signed status (0 = OK)
        bool ackOk = false;
        int errStatus = -1;
        final sw = Stopwatch()..start();
        final maxWaitMs = (cmd == 0x03 || cmd == 0x04) ? 2500 : 1500;

        while (sw.elapsedMilliseconds < maxWaitMs) {
          if (rxBuffer.length >= 22) {
            for (int idx = 0; idx <= rxBuffer.length - 22; idx++) {
              if (rxBuffer[idx] == 0x48 && rxBuffer[idx + 1] == 0x52) { // Header 'HR'
                final replyCmd = rxBuffer[idx + 20];
                final status = rxBuffer[idx + 21];
                if (replyCmd == cmd) {
                  if (status == 0x00) {
                    ackOk = true;
                  } else {
                    errStatus = status;
                  }
                  // Tiêu thụ gói ACK (chuẩn 31..35 bytes kết thúc bằng 0xAA) khỏi buffer
                  int endIdx = idx + 28;
                  while (endIdx < rxBuffer.length && rxBuffer[endIdx] != 0xAA) {
                    endIdx++;
                  }
                  if (endIdx < rxBuffer.length && rxBuffer[endIdx] == 0xAA) {
                    endIdx++;
                  }
                  if (endIdx > rxBuffer.length) endIdx = rxBuffer.length;
                  rxBuffer.removeRange(0, endIdx);
                  break;
                }
              }
            }
            if (ackOk || errStatus >= 0) break;
          }
          await Future.delayed(const Duration(milliseconds: 15));
        }

        if (ackOk) {
          ackSuccessCount++;
          if (cmd == 0x04) cmd04AckOk = true;
          onLog?.call('  [ACK OK] Card nhận thành công gói $cmdHex.');
        } else if (errStatus >= 0) {
          onLog?.call(
            '  [CẢNH BÁO] Card phản hồi mã lỗi 0x${errStatus.toRadixString(16).toUpperCase()} cho gói $cmdHex.',
          );
        } else {
          onLog?.call('  [ĐÃ PHÁT] Gói $cmdHex đã truyền đi.');
        }

        await Future.delayed(const Duration(milliseconds: 35));
      }

      // ĐẶC BIỆT QUAN TRỌNG: Sau gói Cmd 0x04 (Hoàn tất truyền file), 
      // card HD-WF2 cần thời gian lưu dữ liệu vào chip SPI flash và kích hoạt HUB75.
      onLog?.call('  [LƯU FLASH] Đang hoàn tất lưu chương trình vào bộ nhớ card...');
      await Future.delayed(const Duration(milliseconds: 650));

      await sub.cancel();

      // Bắt buộc gói chốt hạ 0x04 phải được card xác nhận ACK OK (hoặc tối thiểu >= 3 gói ACK OK)
      final bool isSuccess = cmd04AckOk || (ackSuccessCount >= 3 && sentPackets == packets.length);
      return isSuccess;
    } catch (e) {
      onLog?.call('  [LỖI SOCKET] Không thể giao tiếp tới $ip:$port ($e)');
      return false;
    } finally {
      try {
        await socket?.close();
      } catch (_) {}
    }
  }

  /// Quy trình nạp một bảng:
  /// 1. Kiểm tra Wi-Fi hiện tại -> nếu khác thì tự động kết nối
  /// 2. Bắt buộc kiểm tra đúng SSID của card mới nạp, tránh nạp đè làm tắt card khác
  static Future<bool> updateSingleBoard({
    required LedBoard board,
    required List<Uint8List> packets,
    required Function(String status) onStatus,
    bool allowFallbackToCurrentWifi = true,
  }) async {
    final currentSsid = await getCurrentWifiSsid();
    if (currentSsid.isNotEmpty &&
        currentSsid.toLowerCase() == board.ssid.toLowerCase()) {
      onStatus('  [WIFI] Đang kết nối đúng card: ${board.ssid}');
      await bindCurrentWifi();
    } else {
      onStatus('  [WIFI] Đang kết nối sang Wi-Fi: ${board.ssid}...');
      final connected = await connectToBoardWifi(board.ssid, board.password);
      // Chờ 900ms để Android/MIUI hoàn tất cấp phát IP DHCP 192.168.4.x
      await Future.delayed(const Duration(milliseconds: 900));
      await bindCurrentWifi();

      if (!connected) {
        final afterSsid = await getCurrentWifiSsid();
        final isMatchedNow = afterSsid.isNotEmpty &&
            afterSsid.toLowerCase() == board.ssid.toLowerCase();

        if (!isMatchedNow) {
          // Nếu nhận diện rõ ràng đang bắt một card WF2 KHÁC (ví dụ card 1 đang bật mà gửi cho card 2), chặn ngay để tránh tắt bảng
          if (afterSsid.isNotEmpty &&
              afterSsid.toLowerCase().startsWith('wf2_') &&
              afterSsid.toLowerCase() != board.ssid.toLowerCase()) {
            onStatus(
              '  [CHẶN] Đang bắt Wi-Fi "$afterSsid" khác với "${board.ssid}". Không gửi để tránh tắt bảng!',
            );
            return false;
          }

          if (!allowFallbackToCurrentWifi) {
            onStatus(
              '  [CẢNH BÁO] Chưa kết nối Wi-Fi ${board.ssid}. Khi hộp thoại Android hiện lên, hãy bấm "Kết nối"!',
            );
            return false;
          }
          onStatus('  [WIFI] Thử phát lệnh tới card tại 192.168.4.1...');
        }
      }
    }

    var sent = await sendPacketsToBoard(
      ip: board.ip,
      port: board.port,
      packets: packets,
      onLog: onStatus,
    );

    if (!sent) {
      onStatus('  [THỬ LẠI] Đang thử truyền lại lần 2 cho ${board.name}...');
      await Future.delayed(const Duration(milliseconds: 500));
      await bindCurrentWifi();
      sent = await sendPacketsToBoard(
        ip: board.ip,
        port: board.port,
        packets: packets,
        onLog: onStatus,
      );
    }

    if (sent) {
      onStatus('  ===> [THÀNH CÔNG] ${board.name} (${board.ssid}) đã sáng chữ mới!');
    } else {
      onStatus('  [LỖI] Card ${board.ssid} không phản hồi tại ${board.ip}:${board.port}');
    }

    return sent;
  }
}
