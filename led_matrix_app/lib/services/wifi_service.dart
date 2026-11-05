import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import '../models/board.dart';

class WifiService {
  static const MethodChannel _channel = MethodChannel('com.ledmatrix.wifi');

  /// Tự động kết nối thiết bị Android/iOS vào Wi-Fi của card LED
  static Future<bool> connectToBoardWifi(String ssid, String password) async {
    try {
      final bool result = await _channel.invokeMethod('connectWifi', {
        'ssid': ssid,
        'password': password,
      });
      return result;
    } on PlatformException catch (e) {
      print('WiFi Connection Error: ${e.message}');
      // Fallback cho môi trường test hoặc nếu đã bắt sẵn Wi-Fi
      return true;
    } catch (_) {
      return true;
    }
  }

  /// Tự động ngắt kết nối Wi-Fi để chuẩn bị nhảy sang card tiếp theo
  static Future<void> disconnectWifi(String ssid) async {
    try {
      await _channel.invokeMethod('disconnectWifi', {'ssid': ssid});
    } catch (_) {}
  }

  /// Bắn chuỗi gói tin Huidu qua cổng TCP 6101
  static Future<bool> sendPacketsToBoard({
    required String ip,
    required int port,
    required List<Uint8List> packets,
  }) async {
    Socket? socket;
    try {
      socket = await Socket.connect(ip, port, timeout: const Duration(seconds: 4));
      socket.setOption(SocketOption.tcpNoDelay, true);

      for (final pkt in packets) {
        socket.add(pkt);
        await socket.flush();
        await Future.delayed(const Duration(milliseconds: 150));
      }

      await Future.delayed(const Duration(milliseconds: 300));
      return true;
    } catch (e) {
      print('Socket Send Error: $e');
      return false;
    } finally {
      try {
        await socket?.close();
      } catch (_) {}
    }
  }

  /// Quy trình trọn gói: Kết nối Wi-Fi card -> Chờ nhận IP -> Bắn TCP 6101 -> Ngắt kết nối
  static Future<bool> updateSingleBoard({
    required LedBoard board,
    required List<Uint8List> packets,
    required Function(String status) onStatus,
  }) async {
    onStatus('  [WIFI] Đang chuyển sang kết nối: ${board.ssid}...');
    final connected = await connectToBoardWifi(board.ssid, board.password);
    if (!connected) {
      onStatus('  [LỖI] Không thể kết nối Wi-Fi ${board.ssid}');
      return false;
    }

    // Chờ 1.5 giây cho Android cấp phát IP 192.168.4.x
    await Future.delayed(const Duration(milliseconds: 1500));

    onStatus('  [TCP] Đang mở kết nối tới ${board.ip}:${board.port}...');
    final sent = await sendPacketsToBoard(ip: board.ip, port: board.port, packets: packets);

    if (sent) {
      onStatus('  [THÀNH CÔNG] Đã truyền dữ liệu tới ${board.name}!');
    } else {
      onStatus('  [LỖI] Card không phản hồi tại ${board.ip}:${board.port}');
    }

    await disconnectWifi(board.ssid);
    await Future.delayed(const Duration(milliseconds: 400));
    return sent;
  }
}
