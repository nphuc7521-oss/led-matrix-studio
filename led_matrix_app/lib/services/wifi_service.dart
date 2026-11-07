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

  /// Tự động kết nối thiết bị Android vào Wi-Fi của card LED (tự động thử lại tối đa 2 lượt nếu hệ thống đang chuyển mạng)
  static Future<bool> connectToBoardWifi(String ssid, String password) async {
    try {
      for (int attempt = 1; attempt <= 2; attempt++) {
        final bool? result = await _channel.invokeMethod<bool>('connectWifi', {
          'ssid': ssid,
          'password': password,
        });
        if (result == true) {
          return true;
        }
        final nowSsid = await getCurrentWifiSsid();
        if (nowSsid.isNotEmpty &&
            nowSsid.toLowerCase() == ssid.toLowerCase()) {
          await bindCurrentWifi();
          return true;
        }
        if (attempt < 2) {
          await Future.delayed(const Duration(milliseconds: 600));
        }
      }
      return false;
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
      // Chờ 150ms sau khi mở cổng TCP 6101 để cầu UART nội bộ trên card HD-WF2 sẵn sàng
      await Future.delayed(const Duration(milliseconds: 150));

      bool isClosing = false;
      final rxBuffer = <int>[];
      final sub = socket.listen(
        (data) => rxBuffer.addAll(data),
        onError: (e) {
          if (!isClosing) {
            onLog?.call('  [LỖI SOCKET] $e');
          }
        },
      );

      bool cmd13AckOk = false;
      bool cmd02AckOk = false;
      bool cmd03AckOk = false;
      bool cmd04AckOk = false;
      bool sent04 = false;

      for (int i = 0; i < packets.length; i++) {
        final pkt = packets[i];
        final cmd = pkt[6];
        final cmdHex =
            '0x${cmd.toRadixString(16).padLeft(2, '0').toUpperCase()}';

        bool ackOk = false;
        int errStatus = -1;

        // Chỉ riêng gói 0x13 (screen.hds - 96B khởi tạo phiên) được phép gửi tối đa 2 lần trên cùng socket
        // giống hệt HDSDK.dll để đánh thức cầu UART của card.
        // Tuyệt đối chỉ gửi 1 lần cho 0x02, 0x03, 0x04 để không bao giờ làm lệch/hỏng bộ đệm file progam.hds!
        final int maxSendTries = (cmd == 0x13) ? 2 : 1;
        final int maxWaitMs = (cmd == 0x03)
            ? 2600
            : (cmd == 0x04)
                ? 2200
                : (cmd == 0x02)
                    ? 2000
                    : 1500;

        for (int sendTry = 1; sendTry <= maxSendTries; sendTry++) {
          if (sendTry == 1) {
            onLog?.call(
              '  [GỬI] Gói $cmdHex (Seq ${i + 1}/${packets.length}, ${pkt.length}B)...',
            );
          } else {
            onLog?.call(
              '  [ĐÁNH THỨC CARD] Phát lại gói khởi tạo $cmdHex (lần 2)...',
            );
          }

          if (cmd == 0x04) {
            // Card có thể tự khởi động lại bộ hiển thị ngay khi nhận 0x04 gây đóng socket sớm (errno 103)
            isClosing = true;
          }

          try {
            // Với gói dữ liệu lớn (0x03 = 920..935 bytes), chia thành từng khung 256 bytes cách nhau 15ms
            // để bộ đệm FIFO UART nội bộ của chip Wi-Fi trên card HD-WF2 không bao giờ bị tràn (tránh lỗi 0x5 hoặc mất ACK)
            if (pkt.length > 256) {
              for (int offset = 0; offset < pkt.length; offset += 256) {
                final int end =
                    (offset + 256 < pkt.length) ? offset + 256 : pkt.length;
                socket.add(pkt.sublist(offset, end));
                await socket.flush();
                if (end < pkt.length) {
                  await Future.delayed(const Duration(milliseconds: 15));
                }
              }
            } else {
              socket.add(pkt);
              await socket.flush();
            }
            if (cmd == 0x04) sent04 = true;
          } catch (e) {
            if (cmd == 0x04 && cmd03AckOk) {
              sent04 = true;
              break;
            }
            rethrow;
          }

          final sw = Stopwatch()..start();
          while (sw.elapsedMilliseconds < maxWaitMs) {
            if (rxBuffer.length >= 22) {
              for (int idx = 0; idx <= rxBuffer.length - 22; idx++) {
                if (rxBuffer[idx] == 0x48 && rxBuffer[idx + 1] == 0x52) {
                  // Header 'HR'
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
                    while (
                        endIdx < rxBuffer.length && rxBuffer[endIdx] != 0xAA) {
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
          if (cmd == 0x13) cmd13AckOk = true;
          if (cmd == 0x02) cmd02AckOk = true;
          if (cmd == 0x03) cmd03AckOk = true;
          if (cmd == 0x04) cmd04AckOk = true;
          onLog?.call('  [ACK OK] Card nhận thành công gói $cmdHex.');
        } else if (errStatus >= 0) {
          onLog?.call(
            '  [CẢNH BÁO] Card phản hồi mã lỗi 0x${errStatus.toRadixString(16).toUpperCase()} cho gói $cmdHex.',
          );
          // Bắt buộc dừng ngay nếu bất kỳ gói khởi tạo (0x13, 0x02) hoặc dữ liệu (0x03) báo lỗi
          if (cmd == 0x13 || cmd == 0x02 || cmd == 0x03) break;
        } else {
          onLog?.call('  [ĐÃ PHÁT] Gói $cmdHex đã truyền đi.');
          // TUYỆT ĐỐI DỪNG NGAY nếu 0x13, 0x02 hoặc 0x03 chưa có ACK OK!
          // Không bao giờ được gửi gói chốt 0x04 (EndSendFile) khi gói 0x03 (dữ liệu progam.hds) chưa ACK OK,
          // vì gửi 0x04 khi thiếu 0x03 sẽ làm card lưu file rỗng gây tối màn hình!
          if (cmd == 0x13 || cmd == 0x02 || cmd == 0x03) break;
        }

        // Nghỉ 90ms sau 0x13 và 0x02 để MCU của card chuẩn bị xong bộ đệm Flash trước khi nhận 935B của 0x03
        await Future.delayed(
          Duration(milliseconds: (cmd == 0x13 || cmd == 0x02) ? 90 : 60),
        );
      }

      // Chỉ thành công khi CẢ 3 gói 0x13, 0x02, 0x03 đều đã nhận ACK OK (status=0x00) và gói 0x04 đã được phát
      final bool isSuccess =
          cmd13AckOk && cmd02AckOk && cmd03AckOk && (cmd04AckOk || sent04);

      // ĐẶC BIỆT QUAN TRỌNG: Sau gói Cmd 0x04 (Hoàn tất truyền file),
      // giữ nguyên kết nối TCP và Wi-Fi trong 1200ms (giống v1.0.31) để card ghi xong SPI flash
      // và khởi động lại bộ quét HUB75 mượt mà trước khi đóng socket!
      if (isSuccess) {
        onLog?.call(
          '  [LƯU FLASH] Đang hoàn tất lưu chương trình vào bộ nhớ card...',
        );
        await Future.delayed(const Duration(milliseconds: 1200));
      }

      isClosing = true;
      await sub.cancel();
      try {
        await socket.close();
      } catch (_) {}
      socket = null;
      // Chờ 200ms để gói TCP FIN được truyền hoàn tất qua Wi-Fi tới card, giải phóng sạch cổng 6101
      await Future.delayed(const Duration(milliseconds: 200));

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
      // Chờ 1200ms để Android/MIUI hoàn tất cấp phát IP DHCP 192.168.4.x và ổn định bảng định tuyến ARP của card
      await Future.delayed(const Duration(milliseconds: 1200));
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

    var sent = false;
    for (int tryIdx = 1; tryIdx <= 3; tryIdx++) {
      if (tryIdx > 1) {
        onStatus(
          '  [THỬ LẠI LẦN $tryIdx/3] Đang ổn định kênh truyền cho ${board.name}...',
        );
        // Kiểm tra nếu Wi-Fi bị tuột khỏi card thì mới kết nối lại, còn nếu vẫn đang giữ đúng sóng card thì chỉ mở lại TCP nhanh!
        final nowSsid = await getCurrentWifiSsid();
        if (nowSsid.isEmpty ||
            nowSsid.toLowerCase() != board.ssid.toLowerCase()) {
          await connectToBoardWifi(board.ssid, board.password);
          await Future.delayed(const Duration(milliseconds: 1000));
        } else {
          await Future.delayed(const Duration(milliseconds: 800));
        }
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
      onStatus(
        '  ===> [THÀNH CÔNG] ${board.name} (${board.ssid}) đã sáng chữ mới!',
      );
    } else {
      onStatus(
        '  [LỖI] Card ${board.ssid} không phản hồi tại ${board.ip}:${board.port}',
      );
    }

    return sent;
  }
}
