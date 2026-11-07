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
  static Future<bool> connectToBoardWifi(
    String ssid,
    String password, {
    bool force = false,
  }) async {
    try {
      if (force) {
        await disconnectWifi(ssid);
        await Future.delayed(const Duration(milliseconds: 350));
      }
      final bool? result = await _channel.invokeMethod<bool>('connectWifi', {
        'ssid': ssid,
        'password': password,
        'force': force,
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
      // Chờ 200ms sau khi mở cổng TCP 6101 để cầu UART nội bộ trên card HD-WF2 sẵn sàng nhận gói 0x13
      await Future.delayed(const Duration(milliseconds: 200));

      bool transferFinished = false;
      final rxBuffer = <int>[];
      final sub = socket.listen(
        (data) => rxBuffer.addAll(data),
        onError: (e) {
          if (!transferFinished) {
            onLog?.call('  [LỖI SOCKET] $e');
          }
        },
      );

      int ackSuccessCount = 0;
      int sentPackets = 0;
      bool cmd03AckOk = false;
      bool cmd04AckOk = false;

      for (int i = 0; i < packets.length; i++) {
        final pkt = packets[i];
        final cmd = pkt[6];
        final cmdHex =
            '0x${cmd.toRadixString(16).padLeft(2, '0').toUpperCase()}';

        bool ackOk = false;
        int errStatus = -1;
        // Giống cơ chế của HDSDK.dll: nếu gói tin chưa nhận được phản hồi HR trên kênh TCP đang mở,
        // phát lại ngay trên CÙNG kết nối TCP (tối đa 2 lần) thay vì đóng socket mở kết nối mới làm treo cổng 6101 của card!
        final int maxInSocketTries = (cmd == 0x04) ? 1 : 2;
        final int maxWaitMs = (cmd == 0x03 || cmd == 0x04) ? 2400 : 1800;

        for (int sendTry = 1; sendTry <= maxInSocketTries; sendTry++) {
          if (sendTry == 1) {
            onLog?.call(
              '  [GỬI] Gói $cmdHex (Seq ${i + 1}/${packets.length}, ${pkt.length}B)...',
            );
          } else {
            onLog?.call(
              '  [GỬI LẠI] Gói $cmdHex trên cùng kênh TCP (lần $sendTry/$maxInSocketTries)...',
            );
          }

          try {
            socket.add(pkt);
            await socket.flush();
            if (sendTry == 1) sentPackets++;
          } catch (e) {
            // Nếu ở gói chốt 0x04 mà card tự khởi động lại chương trình gây ngắt socket thì vẫn hợp lệ nếu 0x03 đã ACK OK
            if (cmd == 0x04 && cmd03AckOk) {
              break;
            }
            rethrow;
          }

          final sw = Stopwatch()..start();
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

          if (ackOk || errStatus >= 0) break;
        }

        if (ackOk) {
          ackSuccessCount++;
          if (cmd == 0x03) cmd03AckOk = true;
          if (cmd == 0x04) cmd04AckOk = true;
          onLog?.call('  [ACK OK] Card nhận thành công gói $cmdHex.');
        } else if (errStatus >= 0) {
          onLog?.call(
            '  [CẢNH BÁO] Card phản hồi mã lỗi 0x${errStatus.toRadixString(16).toUpperCase()} cho gói $cmdHex.',
          );
          if (cmd == 0x02 || cmd == 0x03) break;
        } else {
          onLog?.call('  [ĐÃ PHÁT] Gói $cmdHex đã truyền đi.');
          // Chỉ dừng nếu gói khởi tạo file 0x02 hoặc dữ liệu 0x03 không phản hồi;
          // nếu riêng 0x13 (screen.hds) không phản hồi vẫn tiếp tục gửi 0x02 -> 0x03 -> 0x04!
          if (cmd == 0x02 || cmd == 0x03) break;
        }

        await Future.delayed(const Duration(milliseconds: 50));
      }

      // ĐÁNH DẤU KẾT THÚC PHIÊN & ĐÓNG CỔNG TCP NGAY KHI WI-FI ĐANG KẾT NỐI!
      // Điều này đảm bảo gói TCP FIN/ACK được gửi hoàn tất tới card (192.168.4.1:6101) trước khi điện thoại ngắt Wi-Fi,
      // giúp giải phóng dứt điểm cổng 6101 trên card cho các lần nạp thứ 2, 3, 4, 5 tiếp theo!
      transferFinished = true;
      await sub.cancel();
      try {
        await socket.flush();
      } catch (_) {}
      try {
        await socket.close();
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 250));
      try {
        socket.destroy();
      } catch (_) {}
      socket = null;

      // Bắt buộc gói chốt hạ 0x04 hoặc gói dữ liệu chương trình 0x03 (kèm đã phát 0x04) phải được card xác nhận ACK OK
      final bool isSuccess = cmd04AckOk || (cmd03AckOk && sentPackets == packets.length);

      if (isSuccess) {
        onLog?.call('  [LƯU FLASH] Đang hoàn tất lưu chương trình vào bộ nhớ card...');
        await Future.delayed(const Duration(milliseconds: 950));
      }

      return isSuccess;
    } catch (e) {
      onLog?.call('  [LỖI SOCKET] Không thể giao tiếp tới $ip:$port ($e)');
      return false;
    } finally {
      try {
        await socket?.close();
      } catch (_) {}
      try {
        socket?.destroy();
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
    onStatus('  [WIFI] Đang kết nối sang Wi-Fi: ${board.ssid}...');
    final connected = await connectToBoardWifi(
      board.ssid,
      board.password,
      force: false,
    );
    // Chờ 900ms để Android/MIUI ổn định bảng định tuyến ARP của card sau khi đã nhận IP 192.168.4.x
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

    var sent = false;
    for (int tryIdx = 1; tryIdx <= 3; tryIdx++) {
      if (tryIdx > 1) {
        onStatus('  [THỬ LẠI LẦN $tryIdx/3] Đang làm mới kết nối Wi-Fi & kênh truyền cho ${board.name}...');
        await connectToBoardWifi(board.ssid, board.password, force: true);
        await Future.delayed(const Duration(milliseconds: 800));
        await bindCurrentWifi();
      }
      sent = await sendPacketsToBoard(
        ip: board.ip,
        port: board.port,
        packets: packets,
        onLog: onStatus,
      );
      if (sent) break;
    }

    if (sent) {
      onStatus('  ===> [THÀNH CÔNG] ${board.name} (${board.ssid}) đã sáng chữ mới!');
    } else {
      onStatus('  [LỖI] Card ${board.ssid} không phản hồi tại ${board.ip}:${board.port}');
    }

    return sent;
  }
}
