import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/board.dart';

class HuiduProtocol {
  static const int screenWidth = 64;
  static const int screenHeight = 32;

  /// Đóng gói gói tin chuẩn HD2020:
  /// Magic "HT\0\x1B", 2B TotalLen (BE), 1B Cmd, 19B zeros, 1B Seq, Payload, 2B Sum16 (BE), 1B 0xAA
  static Uint8List buildPacket({
    required int cmd,
    required int seq,
    required Uint8List payload,
  }) {
    const headerLen = 27;
    final totalLen = headerLen + payload.length + 3;
    final packet = Uint8List(totalLen);

    packet[0] = 0x48; // 'H'
    packet[1] = 0x54; // 'T'
    packet[2] = 0x00;
    packet[3] = 0x1B; // 27 bytes header

    packet[4] = (totalLen >> 8) & 0xFF;
    packet[5] = totalLen & 0xFF;

    packet[6] = cmd & 0xFF;

    // Bytes 7..25 là 19 byte 0x00 (hoặc GUID padding)
    packet[26] = seq & 0xFF;

    // Chép Payload bắt đầu từ byte 27
    packet.setRange(headerLen, headerLen + payload.length, payload);

    // Tính Checksum 16-bit (Sum của tất cả các byte từ 0 đến totalLen - 4)
    int sum = 0;
    for (int i = 0; i < totalLen - 3; i++) {
      sum += packet[i];
    }

    packet[totalLen - 3] = (sum >> 8) & 0xFF;
    packet[totalLen - 2] = sum & 0xFF;
    packet[totalLen - 1] = 0xAA; // Byte kết thúc chuẩn 0xAA

    return packet;
  }

  /// Template nhị phân 66 bytes chuẩn của `screen.hds` (được trích xuất từ HDSDK)
  static Uint8List getScreenHds() {
    return Uint8List.fromList([
      0x48, 0x53, 0x00, 0x42, 0x00, 0x40, 0x00, 0x20,
      0x00, 0x01, 0x02, 0x06, 0x00, 0x54, 0x60, 0x01,
      0x35, 0x60, 0x00, 0x00, 0x00, 0x31, 0x31, 0x31,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00,
      0x08, 0x00, 0x08, 0x00, 0x00, 0x00, 0x08, 0x00,
      0x10, 0x00, 0x08, 0x00, 0x04, 0x00, 0x10, 0x00,
      0x08, 0x00, 0x08, 0x02, 0x01, 0x00, 0x00, 0x00,
      0x00, 0x00
    ]);
  }

  /// Chuyển đổi mã màu sang Color
  static Color parseColor(String c) {
    switch (c.toLowerCase()) {
      case 'red':
        return const Color(0xFFFF0000);
      case 'green':
        return const Color(0xFF00FF00);
      case 'blue':
        return const Color(0xFF0088FF);
      case 'yellow':
        return const Color(0xFFFFFF00);
      case 'cyan':
        return const Color(0xFF00FFFF);
      case 'magenta':
        return const Color(0xFFFF00FF);
      case 'white':
        return const Color(0xFFFFFFFF);
      default:
        return const Color(0xFF00FF00);
    }
  }

  /// Render nội dung chữ tiếng Việt của Bảng thành mảng 3-plane RGB bitmap
  /// Trả về mảng byte 3 mặt phẳng: [Plane Red, Plane Green, Plane Blue]
  static Future<Uint8List> renderTextToRgbPlanes(
    LedBoard board, {
    required int width,
    required int height,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    );

    // 1. Nền đen
    final bgPaint = Paint()..color = const Color(0xFF000000);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      bgPaint,
    );

    // 2. Kiểu chữ & Màu sắc
    final isRainbow = board.colorfulWords > 0;
    final baseColor = parseColor(board.color);

    final textStyle = TextStyle(
      color: isRainbow ? Colors.white : baseColor,
      fontSize: board.fontSize.toDouble(),
      fontWeight: board.bold ? FontWeight.bold : FontWeight.normal,
      fontStyle: board.italic ? FontStyle.italic : FontStyle.normal,
      decoration:
          board.underline ? TextDecoration.underline : TextDecoration.none,
      fontFamily: board.fontFamily,
    );

    TextAlign align = TextAlign.center;
    if (board.alignH == 'left') align = TextAlign.left;
    if (board.alignH == 'right') align = TextAlign.right;

    final textSpan = TextSpan(
      text: board.text.isEmpty ? ' ' : board.text,
      style: textStyle,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textAlign: align,
      textDirection: TextDirection.ltr,
      maxLines: 2,
    );

    textPainter.layout(maxWidth: width.toDouble());

    // Căn chỉnh trục dọc
    double top = (height - textPainter.height) / 2;
    if (board.alignV == 'top') top = 0;
    if (board.alignV == 'bottom') top = height - textPainter.height;
    if (top < 0) top = 0;

    double left = (width - textPainter.width) / 2;
    if (board.alignH == 'left') left = 1;
    if (board.alignH == 'right') left = width - textPainter.width - 1;
    if (left < 0) left = 0;

    textPainter.paint(canvas, Offset(left, top));

    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final rgbaBytes = byteData!.buffer.asUint8List();

    // 3. Tách thành 3 Plane: Red, Green, Blue
    final rowBytes = (width + 7) ~/ 8;
    final planeSize = rowBytes * height;

    final redPlane = Uint8List(planeSize);
    final greenPlane = Uint8List(planeSize);
    final bluePlane = Uint8List(planeSize);

    // Danh sách màu cầu vồng khi bật 7 màu [AB]
    final rainbowPalette = [
      [255, 0, 0], // Đỏ
      [255, 255, 0], // Vàng
      [0, 255, 0], // Xanh lá
      [0, 255, 255], // Xanh ngọc
      [0, 100, 255], // Lam
      [255, 0, 255], // Hồng tím
    ];

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixelIdx = (y * width + x) * 4;
        final r = rgbaBytes[pixelIdx];
        final g = rgbaBytes[pixelIdx + 1];
        final b = rgbaBytes[pixelIdx + 2];
        final a = rgbaBytes[pixelIdx + 3];

        if (a > 60) {
          final byteIdx = y * rowBytes + (x ~/ 8);
          final bitMask = 0x80 >> (x % 8);

          if (isRainbow) {
            // Phân phối 7 màu cầu vồng theo chiều ngang
            final colorIdx = ((x * rainbowPalette.length) ~/ width) % rainbowPalette.length;
            final pal = rainbowPalette[colorIdx];
            if (pal[0] > 0) redPlane[byteIdx] |= bitMask;
            if (pal[1] > 0) greenPlane[byteIdx] |= bitMask;
            if (pal[2] > 0) bluePlane[byteIdx] |= bitMask;
          } else {
            if (r > 60) redPlane[byteIdx] |= bitMask;
            if (g > 60) greenPlane[byteIdx] |= bitMask;
            if (b > 60) bluePlane[byteIdx] |= bitMask;
          }
        }
      }
    }

    final outPlanes = Uint8List(planeSize * 3);
    outPlanes.setRange(0, planeSize, redPlane);
    outPlanes.setRange(planeSize, planeSize * 2, greenPlane);
    outPlanes.setRange(planeSize * 2, planeSize * 3, bluePlane);

    return outPlanes;
  }

  /// Sinh gói tin nhị phân `progam.hds` hoàn chỉnh nạp vào card
  static Uint8List buildProgamHds(LedBoard board, Uint8List rgbPlanes) {
    final hasBorder = board.borderStyle > 0;

    // Header 1: HC (Chunk Header) - 29 bytes
    final hc = [
      0x48, 0x43, 0x19, 0x00, 0x01, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1D
    ];

    // Xác định mã hiệu ứng phần cứng
    int effCode = board.effect;
    if (effCode == 202) effCode = 0x01; // Continuous Move Left -> Move Left 1
    if (effCode == 37) effCode = 0x25;  // Pull Up = 37 (0x25)
    if (effCode == 36) effCode = 0x24;  // Pull Down = 36 (0x24)
    if (effCode == 38) effCode = 0x26;  // Stretch V
    if (effCode == 39) effCode = 0x27;  // Stretch H

    final speed = board.speed.clamp(1, 20);
    final stay = board.stayTime.clamp(0, 10);

    if (!hasBorder) {
      // === CHẾ ĐỘ TOÀN MÀN HÌNH 64x32 (KHÔNG VIỀN) ===
      // HP Header: 55 bytes
      final hp = [
        0x48, 0x50, 0x00, 0x33, 0x01, 0x00, 0x00, 0x00, 0x00, 0x01, 0x51, 0x7F, 0x00, 0x00, 0x02, 0x58,
        0x7F, 0x00, 0x6A, 0xED, 0x18, 0x80, 0x6A, 0xF7, 0xA4, 0x7F, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x03, 0x76, 0xB6, 0xFF, 0xBC, 0xFB, 0xE6, 0x3D, 0x16, 0xB6, 0x8F, 0xCE, 0x01, 0x45, 0x96, 0x21,
        0x00, 0x01, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x3C, 0xFF, 0xFF, 0xFF, 0xFF
      ];

      // HA Area Header: 63 bytes (Width = 64, Height = 32)
      final ha = [
        0x48, 0x41, 0x00, 0x19, 0x00, 0x00, 0x00, 0x00, 0x00, 0x40, 0x00, 0x20, 0x00, 0x01, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1D, 0x00, 0x16, 0x30,
        0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0xFF, 0xFF, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00, 0x00, 0x1D,
        0x00, 0xFF, 0xFF,
        effCode & 0xFF, // Byte 0x8C: Effect ID
        0xC9,           // Byte 0x8D: ClearType = 201 (Do not clear)
        0x00,           // Byte 0x8E
        speed & 0xFF,   // Byte 0x8F: Speed
        stay & 0xFF,    // Byte 0x90: Stay Time
        0x00, 0x00      // Byte 0x91..0x92
      ];

      final out = BytesBuilder();
      out.add(hc);
      out.add(hp);
      out.add(ha);
      out.add(rgbPlanes); // 768 bytes
      return out.toBytes();
    } else {
      // === CHẾ ĐỘ VIỀN CHẠY ĐỘC LẬP (KHUNG CHỮ 62x30, VIỀN 64x1) ===
      final isAnti = board.borderMode.toLowerCase().contains('anti');
      final bMode = isAnti ? 1 : 0;
      final bSpeed = board.borderSpeed.clamp(1, 10);

      // Strip màu của viền chạy (8 bytes Red, 8 bytes Green, 8 bytes Blue)
      final stripR = List.filled(8, 0x92);
      final stripG = List.filled(8, 0x49);
      final stripB = List.filled(8, 0x24);

      final hpBorder = [
        0x48, 0x50, 0x00, 0x33, 0x01, 0x00, 0x00, 0x00, 0x00, 0x01, 0x51, 0x7F, 0x00, 0x00, 0x02, 0x58,
        0x7F, 0x00, 0x6A, 0xED, 0x18, 0x80, 0x6A, 0xF7, 0xA4, 0x7F, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x03, 0x67, 0x3D, 0xFF, 0x1A, 0xFB, 0x41, 0x59, 0x58, 0xB6, 0x8B, 0xDB, 0x01, 0x25, 0x6F, 0xF5,
        0x00, 0x01, 0xFF,
        0x0A, 0x01, 0x01, 0x40,
        bMode & 0xFF,   // Mode: 0 Clockwise, 1 Anti-clockwise
        bSpeed & 0xFF,  // Speed
        0x00, 0x18, 0x00, 0x00,
        ...stripR, ...stripG, ...stripB, // 24 bytes dải viền 64x1
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x5D, 0xFF, 0xFF, 0xFF, 0xFF
      ];

      // HA Area Header: Width = 62 (0x003E), Height = 30 (0x001E), X = 1, Y = 1
      final haBorder = [
        0x48, 0x41, 0x00, 0x19, 0x00, 0x01, 0x00, 0x01, 0x00, 0x3E, 0x00, 0x1E, 0x00, 0x01, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1D, 0x00, 0x16, 0x30,
        0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0xFF, 0xFF, 0x00, 0x00, 0x02, 0xD0, 0x00, 0x00, 0x00, 0x1D,
        0x00, 0xFF, 0xFF,
        effCode & 0xFF,
        0xC9,
        0x00,
        speed & 0xFF,
        stay & 0xFF,
        0x00, 0x00
      ];

      final out = BytesBuilder();
      out.add(hc);
      out.add(hpBorder);
      out.add(haBorder);
      out.add(rgbPlanes); // 720 bytes
      return out.toBytes();
    }
  }

  /// Tạo toàn bộ 4 gói tin TCP (Cmd 0x13, 0x02, 0x03, 0x04) sẵn sàng bắn tới card
  static Future<List<Uint8List>> generateBoardPackets(LedBoard board) async {
    final hasBorder = board.borderStyle > 0;
    final int w = hasBorder ? 62 : 64;
    final int h = hasBorder ? 30 : 32;

    // 1. Render văn bản tiếng Việt thành mảng 3 mặt phẳng RGB
    final rgbPlanes = await renderTextToRgbPlanes(board, width: w, height: h);

    // 2. Tạo nội dung tệp progam.hds
    final progamHds = buildProgamHds(board, rgbPlanes);

    // 3. Tạo nội dung tệp screen.hds
    final screenHds = getScreenHds();

    final transferId = Random().nextInt(0xFFFE) + 1;

    // GÓI 1: Cmd 0x13 (Screen setup)
    final p1 = buildPacket(cmd: 0x13, seq: 1, payload: screenHds);

    // GÓI 2: Cmd 0x02 (Bắt đầu truyền tệp)
    final p2Payload = Uint8List(5);
    p2Payload[0] = 0x05;
    p2Payload[1] = transferId & 0xFF;
    p2Payload[2] = (transferId >> 8) & 0xFF;
    p2Payload[3] = 0x00;
    p2Payload[4] = 0x01; // chunkCount = 1
    final p2 = buildPacket(cmd: 0x02, seq: 2, payload: p2Payload);

    // GÓI 3: Cmd 0x03 (Dữ liệu tệp progam.hds)
    final p3Payload = Uint8List(5 + progamHds.length);
    p3Payload[0] = 0x05;
    p3Payload[1] = transferId & 0xFF;
    p3Payload[2] = (transferId >> 8) & 0xFF;
    p3Payload[3] = 0x00; // chunkIndex = 0
    p3Payload[4] = 0x00;
    p3Payload.setRange(5, 5 + progamHds.length, progamHds);
    final p3 = buildPacket(cmd: 0x03, seq: 3, payload: p3Payload);

    // GÓI 4: Cmd 0x04 (Hoàn tất truyền tệp)
    final p4Payload = Uint8List(3);
    p4Payload[0] = 0x03;
    p4Payload[1] = transferId & 0xFF;
    p4Payload[2] = (transferId >> 8) & 0xFF;
    final p4 = buildPacket(cmd: 0x04, seq: 4, payload: p4Payload);

    return [p1, p2, p3, p4];
  }
}
