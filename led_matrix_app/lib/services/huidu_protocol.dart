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

    // Bytes 7..25 là 19 byte 0x00
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

  /// Kiểm tra kênh màu R, G, B bật/tắt cho màu đơn sắc
  static List<bool> _getSolidRgbBits(String c) {
    switch (c.toLowerCase()) {
      case 'red':
        return [true, false, false];
      case 'green':
        return [false, true, false];
      case 'blue':
        return [false, false, true];
      case 'yellow':
        return [true, true, false];
      case 'cyan':
        return [false, true, true];
      case 'magenta':
        return [true, false, true];
      case 'white':
        return [true, true, true];
      default:
        return [false, true, false];
    }
  }

  /// Lấy màu RGB thuần 1-bit cho chế độ Chữ 7 Màu [AB] (1..8) giống hệt Web V18
  static List<int> _getRainbowRgb(
    int preset,
    int x,
    int y,
    int width,
    int height,
  ) {
    const cRed = [255, 0, 0];
    const cYellow = [255, 255, 0];
    const cGreen = [0, 255, 0];
    const cCyan = [0, 255, 255];
    const cBlue = [0, 0, 255];
    const cMagenta = [255, 0, 255];
    const cWhite = [255, 255, 255];

    List<List<int>> palette;
    int span = max(1, width);
    int pos = x;

    switch (preset) {
      case 1: // Cầu vồng 7 màu ngang chuẩn HD2020
        palette = [cRed, cYellow, cGreen, cCyan, cBlue, cMagenta];
        break;
      case 2: // Cầu vồng dọc
        palette = [cRed, cYellow, cGreen, cCyan, cMagenta];
        span = max(1, height);
        pos = y;
        break;
      case 3: // Sóng Neon chéo
        palette = [cMagenta, cCyan, cYellow, cGreen, cRed];
        span = max(1, width + height);
        pos = x + y;
        break;
      case 4: // Hoàng hôn Đỏ - Vàng - Tím - Xanh ngọc
        palette = [cRed, cYellow, cMagenta, cCyan];
        break;
      case 5: // Biển Xanh ngọc - Trắng - Xanh dương
        palette = [cCyan, cWhite, cBlue, cCyan];
        break;
      case 6: // Lửa Đỏ - Vàng - Trắng
        palette = [cRed, cYellow, cWhite, cYellow, cRed];
        break;
      case 7: // Đa sắc Rực rỡ
        palette = [cGreen, cYellow, cCyan, cMagenta, cRed];
        break;
      default: // Cyberpunk Tím - Vàng - Xanh ngọc
        palette = [cMagenta, cYellow, cCyan, cGreen];
        break;
    }

    int idx = (pos * palette.length) ~/ span;
    if (idx < 0) idx = 0;
    if (idx >= palette.length) idx = palette.length - 1;
    return palette[idx];
  }

  /// Sinh 24 bytes dải viền 64x1 pixel chuẩn phần cứng HD2020 cho HP Header (8B Red + 8B Green + 8B Blue)
  static List<int> _buildBorderStrip24Bytes(int borderStyle) {
    const cRed = [1, 0, 0];
    const cYellow = [1, 1, 0];
    const cGreen = [0, 1, 0];
    const cCyan = [0, 1, 1];
    const cBlue = [0, 0, 1];
    const cMagenta = [1, 0, 1];
    const cWhite = [1, 1, 1];
    const cBlack = [0, 0, 0];

    List<List<int>> pattern;
    switch (borderStyle) {
      case 1: // Mẫu 001: Chấm bi Đỏ - Vàng - Lục
        pattern = [cRed, cRed, cBlack, cYellow, cYellow, cBlack, cGreen, cGreen, cBlack];
        break;
      case 2: // Mẫu 002: Sao lấp lánh Trắng - Xanh ngọc
        pattern = [cWhite, cCyan, cBlack, cCyan];
        break;
      case 3: // Mẫu 003: Sóng 7 màu liên tục
        pattern = [cRed, cRed, cYellow, cYellow, cGreen, cGreen, cCyan, cCyan, cBlue, cBlue, cMagenta, cMagenta];
        break;
      case 4: // Mẫu 004: Viền đa sắc Đỏ - Lục - Lam
        pattern = [cRed, cRed, cRed, cBlack, cGreen, cGreen, cGreen, cBlack, cBlue, cBlue, cBlue, cBlack];
        break;
      case 5: // Mẫu 005: Kim cương Tím - Xanh ngọc
        pattern = [cMagenta, cMagenta, cMagenta, cBlack, cCyan, cCyan, cCyan, cBlack];
        break;
      case 6: // Mẫu 006: Đường gạch neon Vàng - Đỏ
        pattern = [cYellow, cYellow, cYellow, cBlack, cRed, cRed, cRed, cBlack];
        break;
      default: // Mẫu 007: Vệt sao băng Xanh lá - Vàng
        pattern = [cGreen, cGreen, cGreen, cYellow, cYellow, cBlack];
        break;
    }

    final stripR = List<int>.filled(8, 0);
    final stripG = List<int>.filled(8, 0);
    final stripB = List<int>.filled(8, 0);

    for (int x = 0; x < 64; x++) {
      final rgb = pattern[x % pattern.length];
      final byteIdx = x ~/ 8;
      final bitMask = 0x80 >> (x % 8);
      if (rgb[0] != 0) stripR[byteIdx] |= bitMask;
      if (rgb[1] != 0) stripG[byteIdx] |= bitMask;
      if (rgb[2] != 0) stripB[byteIdx] |= bitMask;
    }

    return [...stripR, ...stripG, ...stripB];
  }

  /// Render nội dung chữ tiếng Việt của Bảng thành mảng row-interleaved RGB bitmap chuẩn HDSDK:
  /// Mỗi hàng y (0..height-1) gồm đúng 24 bytes: [8B Red, 8B Green, 8B Blue].
  /// Khi có viền (width=62, height=30, areaX=1, areaY=1), mỗi điểm ảnh x (0..61) được dịch sang bit (x + 1) chuẩn HDSDK.
  static Future<Uint8List> renderTextToRgbPlanes(
    LedBoard board, {
    required int width,
    required int height,
  }) async {
    final hasBorder = board.borderStyle > 0;
    final int safeW = hasBorder ? 60 : 62;
    final int safeH = hasBorder ? 28 : 30;

    final String rawText = board.text.trim().isEmpty ? ' ' : board.text.trim();
    int curFontSize = board.fontSize.clamp(8, 28);

    // Tự động co cỡ chữ vừa khít vùng hiển thị an toàn (giống hệt Web V18 GenerateLedBitmapPages)
    const int scratchW = 512;
    const int scratchH = 96;
    Uint8List maskRgba = Uint8List(0);
    int minX = 9999, maxX = -1, minY = 9999, maxY = -1;

    while (curFontSize >= 8) {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        const Rect.fromLTWH(0, 0, 512.0, 96.0),
      );

      canvas.drawRect(
        const Rect.fromLTWH(0, 0, 512.0, 96.0),
        Paint()..color = const Color(0xFF000000),
      );

      final textStyle = TextStyle(
        color: Colors.white,
        fontSize: curFontSize.toDouble(),
        fontWeight: board.bold ? FontWeight.bold : FontWeight.normal,
        fontStyle: board.italic ? FontStyle.italic : FontStyle.normal,
        decoration:
            board.underline ? TextDecoration.underline : TextDecoration.none,
        height: 1.0,
      );

      final textPainter = TextPainter(
        text: TextSpan(text: rawText, style: textStyle),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: rawText.contains('\n') ? 2 : 1,
      );

      textPainter.layout(maxWidth: scratchW.toDouble() - 16);
      textPainter.paint(canvas, const Offset(8, 8));

      final picture = recorder.endRecording();
      final image = await picture.toImage(scratchW, scratchH);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      maskRgba = byteData!.buffer.asUint8List();

      minX = 9999;
      maxX = -1;
      minY = 9999;
      maxY = -1;

      for (int y = 0; y < scratchH; y++) {
        for (int x = 0; x < scratchW; x++) {
          final idx = (y * scratchW + x) * 4;
          if (maskRgba[idx] > 110 || maskRgba[idx + 1] > 110 || maskRgba[idx + 2] > 110) {
            if (x < minX) minX = x;
            if (x > maxX) maxX = x;
            if (y < minY) minY = y;
            if (y > maxY) maxY = y;
          }
        }
      }

      final int tw = (maxX >= minX) ? (maxX - minX + 1) : 0;
      final int th = (maxY >= minY) ? (maxY - minY + 1) : 0;

      if (th > safeH && curFontSize > 8) {
        curFontSize--;
        continue;
      }
      if (tw > safeW && curFontSize > 8) {
        curFontSize--;
        continue;
      }
      break;
    }

    const int rowBytesPerColor = 8; // 64 bits = 8 bytes
    const int rowStride = rowBytesPerColor * 3; // 24 bytes mỗi hàng (8R + 8G + 8B)
    final outBitmap = Uint8List(rowStride * height);

    if (maxX < minX || maskRgba.isEmpty) {
      return outBitmap;
    }

    final int tightW = maxX - minX + 1;
    final int tightH = maxY - minY + 1;

    final int marginX = hasBorder ? 1 : 1;
    final int marginY = hasBorder ? 1 : 1;

    int destX = (width - tightW) ~/ 2;
    if (board.alignH == 'left') {
      destX = marginX;
    } else if (board.alignH == 'right') {
      destX = max(marginX, width - tightW - marginX);
    } else {
      destX = max(0, (width - tightW) ~/ 2);
    }

    int destY = (height - tightH) ~/ 2;
    if (board.alignV == 'top') {
      destY = marginY;
    } else if (board.alignV == 'bottom') {
      destY = max(marginY, height - tightH - marginY);
    } else {
      destY = max(0, (height - tightH) ~/ 2);
    }

    final isRainbow = board.colorfulWords > 0;
    final solidBits = _getSolidRgbBits(board.color);
    final bool solidR = solidBits[0];
    final bool solidG = solidBits[1];
    final bool solidB = solidBits[2];

    for (int ty = 0; ty < tightH; ty++) {
      final int py = destY + ty;
      if (py < 0 || py >= height) continue;

      final int rowBase = py * rowStride;

      for (int tx = 0; tx < tightW; tx++) {
        final int px = destX + tx;
        if (px < 0 || px >= width) continue;

        final int srcIdx = ((minY + ty) * scratchW + (minX + tx)) * 4;
        final bool isLit = maskRgba[srcIdx] > 110 ||
            maskRgba[srcIdx + 1] > 110 ||
            maskRgba[srcIdx + 2] > 110;

        if (!isLit) continue;

        // Khi có viền (62x30 tại X=1, Y=1), HDSDK dịch bit sang phải 1 vị trí (bitPos = px + 1)
        final int bitPos = hasBorder ? (px + 1) : px;
        if (bitPos < 0 || bitPos >= 64) continue;

        final int byteInRow = bitPos ~/ 8;
        final int bitMask = 0x80 >> (bitPos % 8);

        if (isRainbow) {
          final rgb = _getRainbowRgb(board.colorfulWords, tx, ty, tightW, tightH);
          if (rgb[0] > 100) outBitmap[rowBase + byteInRow] |= bitMask;
          if (rgb[1] > 100) outBitmap[rowBase + 8 + byteInRow] |= bitMask;
          if (rgb[2] > 100) outBitmap[rowBase + 16 + byteInRow] |= bitMask;
        } else {
          if (solidR) outBitmap[rowBase + byteInRow] |= bitMask;
          if (solidG) outBitmap[rowBase + 8 + byteInRow] |= bitMask;
          if (solidB) outBitmap[rowBase + 16 + byteInRow] |= bitMask;
        }
      }
    }

    return outBitmap;
  }

  /// Sinh gói tin nhị phân `progam.hds` hoàn chỉnh nạp vào card (khớp 100% từng byte với HDSDK.dll)
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
    if (effCode == 203) effCode = 0x02; // Continuous Move Right -> Move Right 2
    if (effCode == 200) effCode = 0x26; // Pull vertically -> 38 (0x26)
    if (effCode == 37) effCode = 0x25;  // Pull Up = 37 (0x25)
    if (effCode == 36) effCode = 0x24;  // Pull Down = 36 (0x24)
    if (effCode == 38) effCode = 0x26;  // Stretch V
    if (effCode == 39) effCode = 0x27;  // Stretch H

    final speed = board.speed.clamp(1, 20);
    final stay = board.stayTime.clamp(1, 10);

    if (!hasBorder) {
      // === CHẾ ĐỘ TOÀN MÀN HÌNH 64x32 (KHÔNG VIỀN - Tổng 915 bytes) ===
      // HP Header: 60 bytes (0x3C)
      final hp = [
        0x48, 0x50, 0x00, 0x33, 0x01, 0x00, 0x00, 0x00, 0x00, 0x01, 0x51, 0x7F, 0x00, 0x00, 0x02, 0x58,
        0x7F, 0x00, 0x6A, 0xED, 0x18, 0x80, 0x6A, 0xF7, 0xA4, 0x7F, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x03, 0x76, 0xB6, 0xFF, 0xBC, 0xFB, 0xE6, 0x3D, 0x16, 0xB6, 0x8F, 0xCE, 0x01, 0x45, 0x96, 0x21,
        0x00, 0x01, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x3C, 0xFF, 0xFF, 0xFF, 0xFF
      ];

      // HA Area Header: 58 bytes (Width = 64, Height = 32, X = 0, Y = 0, BitmapLen = 0x0300 = 768)
      final ha = [
        0x48, 0x41, 0x00, 0x19, 0x00, 0x00, 0x00, 0x00, 0x00, 0x40, 0x00, 0x20, 0x00, 0x01, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1D, 0x00, 0x16, 0x30,
        0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0xFF, 0xFF, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00, 0x00, 0x1D,
        0x00, 0xFF, 0xFF,
        effCode & 0xFF,
        0xC9, // ClearType = 201 (Do not clear)
        0x00,
        speed & 0xFF,
        stay & 0xFF,
        0x00, 0x00
      ];

      final out = BytesBuilder();
      out.add(hc);
      out.add(hp);
      out.add(ha);
      out.add(rgbPlanes); // 768 bytes
      return out.toBytes();
    } else {
      // === CHẾ ĐỘ VIỀN CHẠY ĐỘC LẬP (KHUNG CHỮ 62x30, VIỀN 64x1 - Tổng 900 bytes) ===
      final isAnti = board.borderMode.toLowerCase().contains('anti');
      final bMode = isAnti ? 1 : 0;
      final bSpeed = board.borderSpeed.clamp(1, 10);

      // 24 bytes dải viền 64x1 theo đúng mẫu 001..007
      final strip24Bytes = _buildBorderStrip24Bytes(board.borderStyle);

      // HP Header có viền: ĐÚNG 93 bytes (0x5D) chuẩn HDSDK.dll
      final hpBorder = [
        0x48, 0x50, 0x00, 0x33, 0x01, 0x00, 0x00, 0x00, 0x00, 0x01, 0x51, 0x7F, 0x00, 0x00, 0x02, 0x58,
        0x7F, 0x00, 0x6A, 0xED, 0x18, 0x80, 0x6A, 0xF7, 0xA4, 0x7F, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x03, 0x67, 0x48, 0xFF, 0xE6, 0xFB, 0x7E, 0x93, 0xFF, 0x3E, 0x02, 0x61, 0x01, 0xD2, 0xFC, 0x39,
        0x00, 0x01, 0xFF,
        0x0A, 0x01, 0x01, 0x40,
        bMode & 0xFF,   // Mode: 0 Clockwise, 1 Anti-clockwise
        bSpeed & 0xFF,  // Speed
        0x00, 0x18, 0x00, 0x00,
        ...strip24Bytes, // 24 bytes dải viền 64x1
        0x00, 0x00, 0x00, // ĐÚNG 3 bytes 0x00 trước 0x5D (tổng HP = 93 bytes = 0x5D)
        0x5D, 0xFF, 0xFF, 0xFF, 0xFF
      ];

      // HA Area Header: 58 bytes (Width = 62 (0x003E), Height = 30 (0x001E), X = 1, Y = 1, BitmapLen = 0x02D0 = 720)
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

    // 1. Render văn bản tiếng Việt thành mảng row-interleaved RGB chuẩn HDSDK
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
