import 'dart:convert';
import 'dart:typed_data';
import '../models/board.dart';

class HuiduProtocol {
  static const int width = 64;
  static const int height = 32;

  static List<int> parseGuid(String? guidStr) {
    if (guidStr == null || guidStr.isEmpty) {
      return [
        0x71, 0x00, 0xFF, 0x00, 0xB2, 0xFA, 0x0D, 0x00,
        0x20, 0x00, 0x01, 0x4E, 0x43, 0x00, 0x00, 0x1A
      ];
    }
    try {
      final clean = guidStr.replaceAll('-', '').replaceAll('{', '').replaceAll('}', '');
      final bytes = <int>[];
      for (int i = 0; i < clean.length && bytes.length < 16; i += 2) {
        bytes.add(int.parse(clean.substring(i, i + 2), radix: 16));
      }
      while (bytes.length < 16) {
        bytes.add(0);
      }
      return bytes;
    } catch (_) {
      return [
        0x71, 0x00, 0xFF, 0x00, 0xB2, 0xFA, 0x0D, 0x00,
        0x20, 0x00, 0x01, 0x4E, 0x43, 0x00, 0x00, 0x1A
      ];
    }
  }

  /// Tính Checksum 16-bit Sum16 chuẩn của giao thức Huidu
  static int calculateChecksum(List<int> bytes) {
    int sum = 0;
    for (int b in bytes) {
      sum = (sum + b) & 0xFFFF;
    }
    return sum;
  }

  /// Đóng gói một gói tin HT hoàn chỉnh: Magic + Length + Cmd + GUID + Payload + Sum16 + 0xAA
  static Uint8List buildPacket({
    required int cmdId,
    required List<int> payload,
    required List<int> guid,
    required int packetIndex,
  }) {
    final builder = BytesBuilder();

    // 1. Magic Header 'HT'
    builder.add([0x48, 0x54]);

    // 2. Version (0x001F)
    builder.add([0x00, 0x1F]);

    final innerData = BytesBuilder();

    // 3. Command ID (LE)
    innerData.add([cmdId & 0xFF, (cmdId >> 8) & 0xFF]);

    // 4. Flags (0xFF 0x00)
    innerData.add([0xFF, 0x00]);

    // 5. Device GUID (16 bytes)
    innerData.add(guid.take(16).toList());

    // 6. Packet Index (LE)
    innerData.add([packetIndex & 0xFF, (packetIndex >> 8) & 0xFF]);

    // 7. Payload Length (LE)
    innerData.add([payload.length & 0xFF, (payload.length >> 8) & 0xFF]);

    // 8. Payload Data
    innerData.add(payload);

    final innerBytes = innerData.toBytes();
    final totalLen = innerBytes.length + 3; // +2 checksum + 1 end byte (0xAA)

    // 9. Total Length (BE)
    builder.add([(totalLen >> 8) & 0xFF, totalLen & 0xFF]);
    builder.add(innerBytes);

    final packetWithoutCrc = builder.toBytes();
    final checksum = calculateChecksum(packetWithoutCrc);

    final finalPacket = BytesBuilder();
    finalPacket.add(packetWithoutCrc);
    finalPacket.add([(checksum >> 8) & 0xFF, checksum & 0xFF]);
    finalPacket.addByte(0xAA); // Kết thúc gói 0xAA

    return finalPacket.toBytes();
  }

  /// Sinh chuỗi các gói tin Huidu nạp trực tiếp vào card HD-WF2
  static List<Uint8List> generateBoardPackets(LedBoard board) {
    final guid = parseGuid(board.guid);
    final now = DateTime.now();
    final timeStr = "${now.year}/${_pad(now.month)}/${_pad(now.day)} "
        "${_pad(now.hour)}:${_pad(now.minute)}:${_pad(now.second)},,hd2020,ead57a0b-cb4e-461d-9a28-c8db62916ed1";
    final timeBytes = ascii.encode(timeStr);

    final List<Uint8List> packets = [];

    // GÓI 1: Command 30 (Khởi tạo thông số màn hình 64x32)
    final p30Payload = BytesBuilder();
    p30Payload.add([0x52, 0x05, 0x00, 0x01, 0x00, 0x11, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x11, 0x00, 0x41, 0x00, 0x11, 0xFF, 0xFF, 0xFF, 0xFF]);
    p30Payload.add(timeBytes);
    p30Payload.addByte(0x00);
    packets.add(buildPacket(cmdId: 30, payload: p30Payload.toBytes(), guid: guid, packetIndex: 1));

    // GÓI 2: Command 19 (Định nghĩa vùng hiển thị Area, hiệu ứng, viền chạy)
    final p19Payload = BytesBuilder();
    p19Payload.add([
      0x52, 0x48, 0x53, 0x00, 0x42, 0x00,
      width, 0x00, height, 0x00, // 64 x 32
      0x01, 0x02, 0x06, 0x00, 0x54, 0x60, 0x01, 0x35, 0x60, 0x01, 0x00, 0x00, 0x01, 0x31, 0x31, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00, 0x08,
      0x00, 0x08, 0x00, 0x00, 0x00, 0x08, 0x00, 0x10, 0x00, 0x08, 0x00, 0x04, 0x00, 0x10, 0x00, 0x08,
      0x00, 0x08, 0x02, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x11, 0x00, 0x01, 0x00, 0x00, 0x00,
      0x00, 0x11, 0x00, 0x41, 0x00, 0x11, 0xFF, 0xFF, 0xFF, 0xFF
    ]);
    p19Payload.add(timeBytes);
    p19Payload.addByte(0x00);
    packets.add(buildPacket(cmdId: 19, payload: p19Payload.toBytes(), guid: guid, packetIndex: 2));

    // GÓI 3: Command 2 (Khởi tạo phiên truyền dữ liệu)
    final p2Payload = BytesBuilder();
    p2Payload.add([0x52, 0x05, 0xA4, 0x96, 0x00, 0x03, 0x00, 0x11, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x11, 0x00, 0x41, 0x00, 0x11, 0xFF, 0xFF, 0xFF, 0xFF]);
    p2Payload.add(timeBytes);
    p2Payload.addByte(0x00);
    packets.add(buildPacket(cmdId: 2, payload: p2Payload.toBytes(), guid: guid, packetIndex: 3));

    // GÓI 4: Command 4 (Kích hoạt chạy chương trình lên LED)
    final p4Payload = BytesBuilder();
    p4Payload.add([0x52, 0x03, 0xA4, 0x96, 0x00, 0x11, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x11, 0x00, 0x41, 0x00, 0x11, 0xFF, 0xFF, 0xFF, 0xFF]);
    p4Payload.add(timeBytes);
    p4Payload.addByte(0x00);
    packets.add(buildPacket(cmdId: 4, payload: p4Payload.toBytes(), guid: guid, packetIndex: 4));

    return packets;
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');
}
