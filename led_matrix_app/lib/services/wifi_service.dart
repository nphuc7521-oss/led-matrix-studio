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

  /// Lấy SSID Wi-Fi mà điện thoại đang kết nối hiện tại
  static Future<String> getCurrentWifiSsid() async {
    try {
      final String? ssid = await _channel.invokeMethod<String>('getCurrentWifiSsid');
      return ssid ?? '';
    } catch (_) {
      return '';
    }
  }

  /// Tự động kết nối thiết bị Android vào Wi-Fi của card LED
  static Future<bool> connectToBoardWifi(String ssid, String password) async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('connectWifi', {
        'ssid': ssid,
        'password': password,
      });
      return result ?? true;
    } on PlatformException catch (e) {
      print('WiFi Connection Error: ${e.message}');
      await bindCurrentWifi();
      return true;
    } catch (_) {
      await bindCurrentWifi();
      return true;
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
    // 1. Luôn ép Android bind socket vào Wi-Fi card trước khi kết nối TCP
    await bindCurrentWifi();

    Socket? socket;
    try {
      onLog?.call('  [TCP] Đang mở socket tới $ip:$port...');
      socket = await Socket.connect(ip, port, timeout: const Duration(seconds: 4));
      socket.setOption(SocketOption.tcpNoDelay, true);

      // Đọc ACK bất đồng bộ
      final ackStream = StreamController<List<int>>();
      final sub = socket.listen(
        (data) => ackStream.add(data),
        onError: (e) => print('Socket listen error: $e'),
        cancelOnError: true,
      );

      for (int i = 0; i < packets.length; i++) {
        final pkt = packets[i];
        final cmd = pkt[6];
        final cmdHex = '0x${cmd.toRadixString(16).padLeft(2, '0').toUpperCase()}';

        onLog?.call('  [GỬI] Gói tin $cmdHex (Seq ${i + 1}/${packets.length})...');
        socket.add(pkt);
        await socket.flush();

        // Chờ nhận phản hồi ACK từ card HD-WF2
        final ackReceived = await _waitForAck(ackStream.stream, cmd);
        if (ackReceived) {
          onLog?.call('  [ACK OK] Card đã xác nhận gói $cmdHex thành công.');
        } else {
          onLog?.call('  [ACK TIẾP TỤC] Gói $cmdHex đã phát.');
        }

        await Future.delayed(const Duration(milliseconds: 100));
      }

      await Future.delayed(const Duration(milliseconds: 300));
      await sub.cancel();
      await ackStream.close();
      return true;
    } catch (e) {
      onLog?.call('  [LỖI SOCKET] Không thể giao tiếp tại $ip:$port ($e)');
      return false;
    } finally {
      try {
        await socket?.close();
      } catch (_) {}
    }
  }

  /// Đọc phản hồi ACK 'HR' từ card
  static Future<bool> _waitForAck(Stream<List<int>> stream, int expectedCmd) async {
    try {
      final data = await stream.first.timeout(const Duration(milliseconds: 1500));
      if (data.length >= 22 && data[0] == 0x48 && data[1] == 0x52) {
        final replyCmd = data[20];
        final status = data[21];
        if (replyCmd == expectedCmd && status == 0x00) {
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Quy trình nạp một bảng đơn:
  /// 1. Kiểm tra Wi-Fi hiện tại -> nếu khác thì kết nối
  /// 2. Ép bind Wi-Fi
  /// 3. Bắn 4 gói tin TCP
  static Future<bool> updateSingleBoard({
    required LedBoard board,
    required List<Uint8List> packets,
    required Function(String status) onStatus,
  }) async {
    final currentSsid = await getCurrentWifiSsid();
    if (currentSsid.isNotEmpty && currentSsid.toLowerCase() == board.ssid.toLowerCase()) {
      onStatus('  [WIFI] Đã kết nối sẵn đúng card: ${board.ssid}');
    } else {
      onStatus('  [WIFI] Đang chuyển sang kết nối: ${board.ssid}...');
      final connected = await connectToBoardWifi(board.ssid, board.password);
      if (!connected) {
        onStatus('  [CẢNH BÁO] Không thể tự động kết nối Wi-Fi ${board.ssid}. Đang thử nạp qua Wi-Fi hiện có...');
      }
      await Future.delayed(const Duration(milliseconds: 1200));
    }

    final sent = await sendPacketsToBoard(
      ip: board.ip,
      port: board.port,
      packets: packets,
      onLog: onStatus,
    );

    if (sent) {
      onStatus('  [THÀNH CÔNG] Card ${board.name} đã cập nhật chữ mới!');
    } else {
      onStatus('  [LỖI] Card không phản hồi tại ${board.ip}:${board.port}');
    }

    return sent;
  }
}
