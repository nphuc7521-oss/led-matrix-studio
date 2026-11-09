import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/board.dart';

class TightTextMask {
  final int width;
  final int height;
  final List<bool> pixels;
  final int litCount;

  const TightTextMask({
    required this.width,
    required this.height,
    required this.pixels,
    required this.litCount,
  });
}

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

  /// Template nhị phân 66 bytes chuẩn của `screen.hds` (được trích xuất từ HDSDK, hỗ trợ độ phân giải tùy biến)
  static Uint8List getScreenHds([int width = 64, int height = 32]) {
    return Uint8List.fromList([
      0x48, 0x53, 0x00, 0x42,
      (width >> 8) & 0xFF, width & 0xFF,
      (height >> 8) & 0xFF, height & 0xFF,
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

  /// Kết xuất 1 dòng văn bản tiếng Việt với từng ký tự nằm trong ô cô lập (không bao giờ dính chữ),
  /// dùng thuật toán phát hiện đỉnh nét (Ridge-Aware Thresholding) giúp nét chữ đậm rõ, không bao giờ đứt nét hay mất dấu.
  static Future<TightTextMask> _renderSingleLineTight({
    required String lineText,
    required int curFontSize,
    required bool bold,
    required bool underline,
    required int safeW,
  }) async {
    final String clean = lineText.trim();
    if (clean.isEmpty) {
      return const TightTextMask(
        width: 1,
        height: 1,
        pixels: [false],
        litCount: 0,
      );
    }

    final List<String> graphemes = clean.characters.toList();
    const int slotW = 36;
    const int cellH = 48;
    final int canvasW = max(1, graphemes.length) * slotW;

    final FontWeight weight = bold ? FontWeight.w700 : FontWeight.w500;
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: curFontSize.toDouble(),
      fontWeight: weight,
      fontStyle: FontStyle.normal,
      fontFamilyFallback: const [
        'Noto Sans Thai',
        'Sukhumvit Set',
        'Thonburi',
        'Arial',
        'Tahoma',
      ],
      height: 1.0,
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, canvasW.toDouble(), cellH.toDouble()),
    );

    for (int i = 0; i < graphemes.length; i++) {
      final String ch = graphemes[i];
      if (ch.trim().isEmpty) continue;

      final tp = TextPainter(
        text: TextSpan(text: ch, style: textStyle),
        textAlign: TextAlign.left,
        textDirection: TextDirection.ltr,
        maxLines: 1,
      );
      tp.layout();
      tp.paint(canvas, Offset(i * slotW + 4.0, 8.0));
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(canvasW, cellH);
    Uint8List rgba;
    try {
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      rgba = byteData!.buffer.asUint8List();
    } finally {
      image.dispose();
      picture.dispose();
    }

    int alphaAt(int px, int py) {
      if (px < 0 || px >= canvasW || py < 0 || py >= cellH) return 0;
      return rgba[(py * canvasW + px) * 4 + 3];
    }

    bool isPixelLit(int px, int py) {
      final int a = alphaAt(px, py);
      if (a >= 115) return true;
      if (a < 72) return false;
      final int leftA = alphaAt(px - 1, py);
      final int rightA = alphaAt(px + 1, py);
      final int topA = alphaAt(px, py - 1);
      final int botA = alphaAt(px, py + 1);
      final bool isHorizPeak = a > leftA + 10 &&
          a >= rightA &&
          rightA < a + 10 &&
          topA < 165 &&
          botA < 165;
      final bool isVertPeak = a > topA + 10 &&
          a >= botA &&
          botA < a + 10 &&
          leftA < 165 &&
          rightA < 165;
      return isHorizPeak || isVertPeak;
    }

    final List<List<List<bool>>?> glyphColsList = [];

    for (int i = 0; i < graphemes.length; i++) {
      final String ch = graphemes[i];
      if (ch.trim().isEmpty) {
        glyphColsList.add(null);
        continue;
      }

      final int slotStartX = i * slotW + 1;
      final int slotEndX = (i + 1) * slotW - 2;

      int cMinX = 9999;
      int cMaxX = -1;
      for (int x = slotStartX; x <= slotEndX; x++) {
        for (int y = 1; y < cellH - 1; y++) {
          if (isPixelLit(x, y)) {
            if (x < cMinX) cMinX = x;
            if (x > cMaxX) cMaxX = x;
          }
        }
      }

      if (cMaxX >= cMinX) {
        final List<List<bool>> charCols = [];
        for (int x = cMinX; x <= cMaxX; x++) {
          final col = List<bool>.filled(cellH, false);
          for (int y = 1; y < cellH - 1; y++) {
            if (isPixelLit(x, y)) {
              col[y] = true;
            }
          }
          charCols.add(col);
        }
        glyphColsList.add(charCols);
      }
    }

    int calcWidth(int letterGap, int spaceWidth) {
      int w = 0;
      bool prevWasChar = false;
      for (final g in glyphColsList) {
        if (g == null) {
          w += spaceWidth;
          prevWasChar = false;
        } else {
          if (prevWasChar) w += letterGap;
          w += g.length;
          prevWasChar = true;
        }
      }
      return w;
    }

    int letterGap = 2;
    int spaceWidth = 4;
    if (calcWidth(letterGap, spaceWidth) > safeW) {
      letterGap = 1;
      spaceWidth = 3;
    }

    final List<List<bool>> finalCols = [];
    bool prevWasChar = false;
    for (final g in glyphColsList) {
      if (g == null) {
        for (int s = 0; s < spaceWidth; s++) {
          finalCols.add(List<bool>.filled(cellH, false));
        }
        prevWasChar = false;
      } else {
        if (prevWasChar) {
          for (int s = 0; s < letterGap; s++) {
            finalCols.add(List<bool>.filled(cellH, false));
          }
        }
        finalCols.addAll(g);
        prevWasChar = true;
      }
    }

    int minY = 9999;
    int maxY = -1;
    for (int x = 0; x < finalCols.length; x++) {
      final col = finalCols[x];
      for (int y = 0; y < cellH; y++) {
        if (col[y]) {
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
    }

    if (underline && maxY >= minY) {
      final int ulY = min(cellH - 1, maxY + 2);
      for (int x = 0; x < finalCols.length; x++) {
        finalCols[x][ulY] = true;
      }
      maxY = ulY;
    }

    if (finalCols.isEmpty || maxY < minY) {
      return const TightTextMask(
        width: 1,
        height: 1,
        pixels: [false],
        litCount: 0,
      );
    }

    final int tightW = finalCols.length;
    final int tightH = maxY - minY + 1;
    final List<bool> pixels = List<bool>.filled(tightW * tightH, false);
    int litCount = 0;

    for (int ty = 0; ty < tightH; ty++) {
      final int srcY = minY + ty;
      for (int tx = 0; tx < tightW; tx++) {
        if (finalCols[tx][srcY]) {
          pixels[ty * tightW + tx] = true;
          litCount++;
        }
      }
    }

    return TightTextMask(
      width: tightW,
      height: tightH,
      pixels: pixels,
      litCount: litCount,
    );
  }

  /// Chia cụm từ dài nhiều chữ (ví dụ: "Siêu Nhân Vàng", "Siêu Nhân Trắng") thành 2 dòng cân đối
  static List<String> _splitIntoTwoBalancedLines(String cleanText) {
    final words =
        cleanText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length < 2) return [cleanText];

    if (words.length == 3) {
      final firstTwo = '${words[0]} ${words[1]}';
      if (firstTwo.characters.length <= 10) {
        return [firstTwo, words[2]];
      }
    }

    int bestK = 1;
    int bestScore = 999999;
    for (int k = 1; k < words.length; k++) {
      final l1 = words.sublist(0, k).join(' ');
      final l2 = words.sublist(k).join(' ');
      final len1 = l1.characters.length;
      final len2 = l2.characters.length;
      final score = max(len1, len2) * 10 + (len1 - len2).abs();
      if (score <= bestScore) {
        bestScore = score;
        bestK = k;
      }
    }

    return [
      words.sublist(0, bestK).join(' '),
      words.sublist(bestK).join(' '),
    ];
  }

  /// Ghép 2 dòng TightTextMask thành 1 mặt nạ 2 dòng căn giữa hoàn chỉnh
  static TightTextMask _combineTwoLines(
    TightTextMask m1,
    TightTextMask m2,
    int lineGap,
  ) {
    final int totalW = max(m1.width, m2.width);
    final int totalH = m1.height + lineGap + m2.height;
    final List<bool> pixels = List<bool>.filled(totalW * totalH, false);
    int litCount = 0;

    final int offX1 = (totalW - m1.width) ~/ 2;
    for (int y = 0; y < m1.height; y++) {
      for (int x = 0; x < m1.width; x++) {
        if (m1.pixels[y * m1.width + x]) {
          pixels[y * totalW + (offX1 + x)] = true;
          litCount++;
        }
      }
    }

    final int offX2 = (totalW - m2.width) ~/ 2;
    final int offY2 = m1.height + lineGap;
    for (int y = 0; y < m2.height; y++) {
      for (int x = 0; x < m2.width; x++) {
        if (m2.pixels[y * m2.width + x]) {
          pixels[(offY2 + y) * totalW + (offX2 + x)] = true;
          litCount++;
        }
      }
    }

    return TightTextMask(
      width: totalW,
      height: totalH,
      pixels: pixels,
      litCount: litCount,
    );
  }

  /// Kết xuất từng ký tự tiếng Việt độc lập với khoảng cách tách chữ rõ nét (tuyệt đối không dính chữ, không đứt nét),
  /// tự động xuống 2 dòng cân đối khi câu dài (như "Siêu Nhân Vàng", "Siêu Nhân Đen", "Siêu Nhân Trắng")
  /// để chữ luôn to, rõ ràng và không bao giờ bị cắt mất chữ cuối.
  static Future<TightTextMask> renderTightTextMask({
    required String text,
    required int fontSize,
    required bool bold,
    required bool italic,
    required bool underline,
    required bool hasBorder,
    int width = 64,
    int height = 32,
  }) async {
    final int safeW = hasBorder ? max(1, width - 4) : max(1, width - 2);
    final int safeH = hasBorder ? max(1, height - 4) : max(1, height - 2);
    final String cleanText =
        text.replaceAll('\r\n', '\n').trim();
    if (cleanText.isEmpty) {
      return const TightTextMask(
        width: 1,
        height: 1,
        pixels: [false],
        litCount: 0,
      );
    }

    final List<String> explicitLines = cleanText
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final String singleLineText = explicitLines.join(' ');
    final words = singleLineText
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    // 1. Thử kết xuất trên 1 dòng nếu không có xuống dòng thủ công
    // Hoặc nếu màn hình thấp (< 24px) không đủ chia 2 dòng
    // Hoặc nếu text ngắn (<= 9 ký tự hoặc 1 từ)
    // Hoặc nếu màn hình đủ rộng để chứa trọn câu trên 1 dòng
    if (explicitLines.length == 1 &&
        (words.length == 1 || singleLineText.characters.length <= 9 || height < 24 || width >= 96)) {
      int curFontSize = fontSize.clamp(10, 24);
      TightTextMask bestSingle = const TightTextMask(
        width: 1,
        height: 1,
        pixels: [false],
        litCount: 0,
      );
      while (curFontSize >= 9) {
        bestSingle = await _renderSingleLineTight(
          lineText: singleLineText,
          curFontSize: curFontSize,
          bold: bold,
          underline: underline,
          safeW: safeW,
        );
        if ((bestSingle.width > safeW || bestSingle.height > safeH) &&
            curFontSize > 9) {
          curFontSize--;
          continue;
        }
        break;
      }
      // Nếu vừa khít 1 dòng ở cỡ chữ >= 12 (hoặc chỉ có 1 từ duy nhất, hoặc chiều cao < 24px), dùng luôn 1 dòng
      if (words.length == 1 ||
          height < 24 ||
          (bestSingle.width <= safeW &&
              bestSingle.height <= safeH &&
              curFontSize >= 12)) {
        return bestSingle;
      }
    }

    // 2. Với cụm từ nhiều chữ dài (như "Siêu Nhân Vàng", "Siêu Nhân Đen", "Siêu Nhân Trắng") trên màn hình cao >= 24px,
    // tự động bố cục 2 dòng cân đối để chữ to gấp đôi, rõ nét 100% và không bao giờ mất chữ cuối!
    if (height >= 24) {
      final List<String> twoLines = explicitLines.length >= 2
          ? [explicitLines[0], explicitLines.sublist(1).join(' ')]
          : _splitIntoTwoBalancedLines(singleLineText);

      if (twoLines.length == 2) {
        int curFontSize = min(fontSize.clamp(10, 24), 15);
        TightTextMask bestTwoLine = const TightTextMask(
          width: 1,
          height: 1,
          pixels: [false],
          litCount: 0,
        );

        while (curFontSize >= 9) {
          final m1 = await _renderSingleLineTight(
            lineText: twoLines[0],
            curFontSize: curFontSize,
            bold: bold,
            underline: underline,
            safeW: safeW,
          );
          final m2 = await _renderSingleLineTight(
            lineText: twoLines[1],
            curFontSize: curFontSize,
            bold: bold,
            underline: underline,
            safeW: safeW,
          );

          final int lineGap = (m1.height + 2 + m2.height <= safeH) ? 2 : 1;
          bestTwoLine = _combineTwoLines(m1, m2, lineGap);

          if ((bestTwoLine.width > safeW || bestTwoLine.height > safeH) &&
              curFontSize > 9) {
            curFontSize--;
            continue;
          }
          break;
        }
        return bestTwoLine;
      }
    }

    // Dự phòng 1 dòng
    return _renderSingleLineTight(
      lineText: singleLineText,
      curFontSize: 10,
      bold: bold,
      underline: underline,
      safeW: safeW,
    );
  }

  /// Render nội dung chữ tiếng Việt của Bảng thành mảng row-interleaved RGB bitmap chuẩn HDSDK:
  /// Mỗi hàng y (0..height-1) gồm [rowBytesPerColor R, rowBytesPerColor G, rowBytesPerColor B].
  /// Khi có viền (areaX=1, areaY=1), mỗi điểm ảnh x được dịch sang bit (x + 1) chuẩn HDSDK.
  static Future<Uint8List> renderTextToRgbPlanes(
    LedBoard board, {
    required int width,
    required int height,
    int? fullScreenWidth,
  }) async {
    final hasBorder = board.borderStyle > 0;
    final String rawText = board.text.trim().isEmpty ? ' ' : board.text.trim();
    final int screenW = fullScreenWidth ?? board.width;

    final mask = await renderTightTextMask(
      text: rawText,
      fontSize: board.fontSize,
      bold: board.bold,
      italic: board.italic,
      underline: board.underline,
      hasBorder: hasBorder,
      width: width,
      height: height,
    );

    final int rowBytesPerColor = (screenW / 8).ceil();
    final int rowStride = rowBytesPerColor * 3;
    final outBitmap = Uint8List(rowStride * height);

    final isRainbow = board.colorfulWords > 0;
    final solidBits = _getSolidRgbBits(board.color);
    final bool solidR = solidBits[0];
    final bool solidG = solidBits[1];
    final bool solidB = solidBits[2];

    if (mask.litCount == 0) {
      // Fallback bitmap font dự phòng khẩn cấp nếu GPU offscreen không xuất pixel
      _renderFallbackBitmap(
        rawText,
        outBitmap,
        width: width,
        height: height,
        screenW: screenW,
        hasBorder: hasBorder,
        isRainbow: isRainbow,
        solidR: solidR,
        solidG: solidG,
        solidB: solidB,
        colorfulWords: board.colorfulWords,
      );
      return outBitmap;
    }

    final int tightW = mask.width;
    final int tightH = mask.height;

    final int marginX = 1;
    final int marginY = 1;

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

    for (int ty = 0; ty < tightH; ty++) {
      final int py = destY + ty;
      if (py < 0 || py >= height) continue;

      final int rowBase = py * rowStride;

      for (int tx = 0; tx < tightW; tx++) {
        final int px = destX + tx;
        if (px < 0 || px >= width) continue;

        final bool isLit = mask.pixels[ty * tightW + tx];
        if (!isLit) continue;

        // Khi có viền, HDSDK dịch bit sang phải 1 vị trí (bitPos = px + 1)
        final int bitPos = hasBorder ? (px + 1) : px;
        if (bitPos < 0 || bitPos >= screenW) continue;

        final int byteInRow = bitPos ~/ 8;
        final int bitMask = 0x80 >> (bitPos % 8);

        if (isRainbow) {
          final rgb = _getRainbowRgb(board.colorfulWords, tx, ty, tightW, tightH);
          if (rgb[0] > 100) outBitmap[rowBase + byteInRow] |= bitMask;
          if (rgb[1] > 100) outBitmap[rowBase + rowBytesPerColor + byteInRow] |= bitMask;
          if (rgb[2] > 100) outBitmap[rowBase + rowBytesPerColor * 2 + byteInRow] |= bitMask;
        } else {
          if (solidR) outBitmap[rowBase + byteInRow] |= bitMask;
          if (solidG) outBitmap[rowBase + rowBytesPerColor + byteInRow] |= bitMask;
          if (solidB) outBitmap[rowBase + rowBytesPerColor * 2 + byteInRow] |= bitMask;
        }
      }
    }

    return outBitmap;
  }

  /// Bảng font 5x7 dự phòng cho các ký tự chữ cái và số
  static const Map<String, List<int>> _font5x7 = {
    'A': [0x7E, 0x11, 0x11, 0x11, 0x7E],
    'B': [0x7F, 0x49, 0x49, 0x49, 0x36],
    'C': [0x3E, 0x41, 0x41, 0x41, 0x22],
    'D': [0x7F, 0x41, 0x41, 0x22, 0x1C],
    'E': [0x7F, 0x49, 0x49, 0x49, 0x41],
    'F': [0x7F, 0x09, 0x09, 0x09, 0x01],
    'G': [0x3E, 0x41, 0x49, 0x49, 0x7A],
    'H': [0x7F, 0x08, 0x08, 0x08, 0x7F],
    'I': [0x00, 0x41, 0x7F, 0x41, 0x00],
    'J': [0x20, 0x40, 0x41, 0x3F, 0x01],
    'K': [0x7F, 0x08, 0x14, 0x22, 0x41],
    'L': [0x7F, 0x40, 0x40, 0x40, 0x40],
    'M': [0x7F, 0x02, 0x0C, 0x02, 0x7F],
    'N': [0x7F, 0x04, 0x08, 0x10, 0x7F],
    'O': [0x3E, 0x41, 0x41, 0x41, 0x3E],
    'P': [0x7F, 0x09, 0x09, 0x09, 0x06],
    'Q': [0x3E, 0x41, 0x51, 0x21, 0x5E],
    'R': [0x7F, 0x09, 0x19, 0x29, 0x46],
    'S': [0x46, 0x49, 0x49, 0x49, 0x31],
    'T': [0x01, 0x01, 0x7F, 0x01, 0x01],
    'U': [0x3F, 0x40, 0x40, 0x40, 0x3F],
    'V': [0x1F, 0x20, 0x40, 0x20, 0x1F],
    'W': [0x7F, 0x20, 0x18, 0x20, 0x7F],
    'X': [0x63, 0x14, 0x08, 0x14, 0x63],
    'Y': [0x07, 0x08, 0x70, 0x08, 0x07],
    'Z': [0x61, 0x51, 0x49, 0x45, 0x43],
    '0': [0x3E, 0x51, 0x49, 0x45, 0x3E],
    '1': [0x00, 0x42, 0x7F, 0x40, 0x00],
    '2': [0x42, 0x61, 0x51, 0x49, 0x46],
    '3': [0x21, 0x41, 0x45, 0x4B, 0x31],
    '4': [0x18, 0x14, 0x12, 0x7F, 0x10],
    '5': [0x27, 0x45, 0x45, 0x45, 0x39],
    '6': [0x3C, 0x4A, 0x49, 0x49, 0x30],
    '7': [0x01, 0x71, 0x09, 0x05, 0x03],
    '8': [0x36, 0x49, 0x49, 0x49, 0x36],
    '9': [0x06, 0x49, 0x49, 0x29, 0x1E],
    ' ': [0x00, 0x00, 0x00, 0x00, 0x00],
  };

  /// Chuẩn hóa ký tự tiếng Việt có dấu về chữ cái gốc cho font 5x7 dự phòng
  static String _normalizeVietnameseChar(String ch) {
    const accents = {
      'á': 'A', 'à': 'A', 'ả': 'A', 'ã': 'A', 'ạ': 'A',
      'ă': 'A', 'ắ': 'A', 'ằ': 'A', 'ẳ': 'A', 'ẵ': 'A', 'ặ': 'A',
      'â': 'A', 'ấ': 'A', 'ầ': 'A', 'ẩ': 'A', 'ẫ': 'A', 'ậ': 'A',
      'đ': 'D',
      'é': 'E', 'è': 'E', 'ẻ': 'E', 'ẽ': 'E', 'ẹ': 'E',
      'ê': 'E', 'ế': 'E', 'ề': 'E', 'ể': 'E', 'ễ': 'E', 'ệ': 'E',
      'í': 'I', 'ì': 'I', 'ỉ': 'I', 'ĩ': 'I', 'ị': 'I',
      'ó': 'O', 'ò': 'O', 'ỏ': 'O', 'õ': 'O', 'ọ': 'O',
      'ô': 'O', 'ố': 'O', 'ồ': 'O', 'ổ': 'O', 'ỗ': 'O', 'ộ': 'O',
      'ơ': 'O', 'ớ': 'O', 'ờ': 'O', 'ở': 'O', 'ỡ': 'O', 'ợ': 'O',
      'ú': 'U', 'ù': 'U', 'ủ': 'U', 'ũ': 'U', 'ụ': 'U',
      'ư': 'U', 'ứ': 'U', 'ừ': 'U', 'ử': 'U', 'ữ': 'U', 'ự': 'U',
      'ý': 'Y', 'ỳ': 'Y', 'ỷ': 'Y', 'ỹ': 'Y', 'ỵ': 'Y',
    };
    final lower = ch.toLowerCase();
    if (accents.containsKey(lower)) return accents[lower]!;
    return ch.toUpperCase();
  }

  /// Kết xuất chữ cái bằng font 5x7 dự phòng siêu sắc nét trực tiếp vào outBitmap
  static void _renderFallbackBitmap(
    String rawText,
    Uint8List outBitmap, {
    required int width,
    required int height,
    required int screenW,
    required bool hasBorder,
    required bool isRainbow,
    required bool solidR,
    required bool solidG,
    required bool solidB,
    required int colorfulWords,
  }) {
    final clean = rawText.trim();
    if (clean.isEmpty) return;

    final chars = clean.split('').map(_normalizeVietnameseChar).toList();
    final int scale = (chars.length <= 5 && height >= 24) ? 2 : 1;
    final int charW = 5 * scale;
    final int charH = 7 * scale;
    final int spacing = scale;
    final int totalW = chars.length * charW + (chars.length - 1) * spacing;

    int startX = max(1, (width - totalW) ~/ 2);
    int startY = max(1, (height - charH) ~/ 2);

    final int rowBytesPerColor = (screenW / 8).ceil();
    final int rowStride = rowBytesPerColor * 3;

    for (int ci = 0; ci < chars.length; ci++) {
      final ch = chars[ci];
      final glyph = _font5x7[ch] ?? _font5x7[' ']!;
      final int cBaseX = startX + ci * (charW + spacing);

      for (int col = 0; col < 5; col++) {
        final colBits = glyph[col];
        for (int row = 0; row < 7; row++) {
          final isBitSet = (colBits & (1 << row)) != 0;
          if (!isBitSet) continue;

          for (int sy = 0; sy < scale; sy++) {
            final py = startY + row * scale + sy;
            if (py < 0 || py >= height) continue;
            final rowBase = py * rowStride;

            for (int sx = 0; sx < scale; sx++) {
              final px = cBaseX + col * scale + sx;
              if (px < 0 || px >= width) continue;

              final int bitPos = hasBorder ? (px + 1) : px;
              if (bitPos < 0 || bitPos >= screenW) continue;

              final int byteInRow = bitPos ~/ 8;
              final int bitMask = 0x80 >> (bitPos % 8);

              if (isRainbow) {
                final rgb = _getRainbowRgb(colorfulWords, px, py, width, height);
                if (rgb[0] > 100) outBitmap[rowBase + byteInRow] |= bitMask;
                if (rgb[1] > 100) outBitmap[rowBase + rowBytesPerColor + byteInRow] |= bitMask;
                if (rgb[2] > 100) outBitmap[rowBase + rowBytesPerColor * 2 + byteInRow] |= bitMask;
              } else {
                if (solidR) outBitmap[rowBase + byteInRow] |= bitMask;
                if (solidG) outBitmap[rowBase + rowBytesPerColor + byteInRow] |= bitMask;
                if (solidB) outBitmap[rowBase + rowBytesPerColor * 2 + byteInRow] |= bitMask;
              }
            }
          }
        }
      }
    }
  }

  /// Sinh gói tin nhị phân `progam.hds` hoàn chỉnh nạp vào card (khớp 100% từng byte với HDSDK.dll)
  static Uint8List buildProgamHds(LedBoard board, Uint8List rgbPlanes) {
    final hasBorder = board.borderStyle > 0;
    final int width = board.width;
    final int height = board.height;

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
    if (effCode <= 0 || effCode > 45) effCode = 0x01; // Mặc định chạy chữ trái an toàn tuyệt đối

    final speed = board.speed.clamp(1, 20);
    final stay = board.stayTime.clamp(1, 10);
    final bitmapLen = rgbPlanes.length;

    if (!hasBorder) {
      // === CHẾ ĐỘ TOÀN MÀN HÌNH (KHÔNG VIỀN) ===
      // HP Header: 60 bytes (0x3C)
      final hp = [
        0x48, 0x50, 0x00, 0x33, 0x01, 0x00, 0x00, 0x00, 0x00, 0x01, 0x51, 0x7F, 0x00, 0x00, 0x02, 0x58,
        0x7F, 0x00, 0x6A, 0xED, 0x18, 0x80, 0x6A, 0xF7, 0xA4, 0x7F, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x03, 0x76, 0xB6, 0xFF, 0xBC, 0xFB, 0xE6, 0x3D, 0x16, 0xB6, 0x8F, 0xCE, 0x01, 0x45, 0x96, 0x21,
        0x00, 0x01, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x3C, 0xFF, 0xFF, 0xFF, 0xFF
      ];

      // HA Area Header: 58 bytes (Độ rộng, Chiều cao và Chiều dài Bitmap động theo cấu hình)
      final ha = [
        0x48, 0x41, 0x00, 0x19,
        0x00, 0x00, // Area X = 0
        0x00, 0x00, // Area Y = 0
        (width >> 8) & 0xFF, width & 0xFF,   // Width (BE)
        (height >> 8) & 0xFF, height & 0xFF, // Height (BE)
        0x00, 0x01, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1D, 0x00, 0x16, 0x30,
        0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0xFF, 0xFF,
        (bitmapLen >> 24) & 0xFF,
        (bitmapLen >> 16) & 0xFF,
        (bitmapLen >> 8) & 0xFF,
        bitmapLen & 0xFF, // BitmapLen (BE)
        0x00, 0x00, 0x00, 0x1D,
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
      out.add(rgbPlanes);
      return out.toBytes();
    } else {
      // === CHẾ ĐỘ VIỀN CHẠY ĐỘC LẬP ===
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
        ...strip24Bytes, // 24 bytes dải viền 64x1 lặp quanh chu vi
        0x00, 0x00, 0x00, // ĐÚNG 3 bytes 0x00 trước 0x5D (tổng HP = 93 bytes = 0x5D)
        0x5D, 0xFF, 0xFF, 0xFF, 0xFF
      ];

      final areaW = max(1, width - 2);
      final areaH = max(1, height - 2);

      // HA Area Header: 58 bytes (Dynamic Area Width, Area Height, BitmapLen)
      final haBorder = [
        0x48, 0x41, 0x00, 0x19,
        0x00, 0x01, // Area X = 1
        0x00, 0x01, // Area Y = 1
        (areaW >> 8) & 0xFF, areaW & 0xFF,   // Area Width (BE)
        (areaH >> 8) & 0xFF, areaH & 0xFF,   // Area Height (BE)
        0x00, 0x01, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1D, 0x00, 0x16, 0x30,
        0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0xFF, 0xFF,
        (bitmapLen >> 24) & 0xFF,
        (bitmapLen >> 16) & 0xFF,
        (bitmapLen >> 8) & 0xFF,
        bitmapLen & 0xFF, // BitmapLen (BE)
        0x00, 0x00, 0x00, 0x1D,
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
      out.add(rgbPlanes);
      return out.toBytes();
    }
  }

  /// Tạo toàn bộ 4 gói tin TCP chuẩn HDSDK (Cmd 0x13, 0x02, 0x03, 0x04) sẵn sàng bắn tới card
  static Future<List<Uint8List>> generateBoardPackets(LedBoard board) async {
    final hasBorder = board.borderStyle > 0;
    final int w = hasBorder ? max(1, board.width - 2) : board.width;
    final int h = hasBorder ? max(1, board.height - 2) : board.height;

    // 1. Render văn bản tiếng Việt thành mảng row-interleaved RGB chuẩn HDSDK
    final rgbPlanes = await renderTextToRgbPlanes(
      board,
      width: w,
      height: h,
      fullScreenWidth: board.width,
    );

    // 2. Tạo nội dung tệp progam.hds
    final progamHds = buildProgamHds(board, rgbPlanes);

    // 3. Tạo nội dung tệp screen.hds (bắt buộc gửi để khởi tạo phiên giao tiếp TCP trên card)
    final screenHds = getScreenHds(board.width, board.height);

    final transferId = Random().nextInt(0xFFFE) + 1;

    // GÓI 1: Cmd 0x13 (Screen setup)
    final p1 = buildPacket(cmd: 0x13, seq: 1, payload: screenHds);

    // GÓI 2: Cmd 0x02 (Bắt đầu truyền tệp progam.hds - Bắt buộc Big-Endian cho transferId như HDSDK)
    final p2Payload = Uint8List(5);
    p2Payload[0] = 0x05;
    p2Payload[1] = (transferId >> 8) & 0xFF; // High byte (BE)
    p2Payload[2] = transferId & 0xFF;        // Low byte (BE)
    p2Payload[3] = 0x00;
    p2Payload[4] = 0x01; // chunkCount = 1 (0x0001 BE)
    final p2 = buildPacket(cmd: 0x02, seq: 2, payload: p2Payload);

    // GÓI 3: Cmd 0x03 (Dữ liệu tệp progam.hds)
    final p3Payload = Uint8List(5 + progamHds.length);
    p3Payload[0] = 0x05;
    p3Payload[1] = (transferId >> 8) & 0xFF; // High byte (BE)
    p3Payload[2] = transferId & 0xFF;        // Low byte (BE)
    p3Payload[3] = 0x00; // chunkIndex = 0 (0x0000 BE)
    p3Payload[4] = 0x00;
    p3Payload.setRange(5, 5 + progamHds.length, progamHds);
    final p3 = buildPacket(cmd: 0x03, seq: 3, payload: p3Payload);

    // GÓI 4: Cmd 0x04 (Hoàn tất truyền tệp - Bắt buộc 0x03 theo chuẩn CHDPack::PackedData(_HD_ENDSENDFILE) tại 0x046FA8)
    final p4Payload = Uint8List(3);
    p4Payload[0] = 0x03;                     // 0x03 = chuẩn HDSDK EndSendFile
    p4Payload[1] = (transferId >> 8) & 0xFF; // High byte (BE)
    p4Payload[2] = transferId & 0xFF;        // Low byte (BE)
    final p4 = buildPacket(cmd: 0x04, seq: 4, payload: p4Payload);

    return [p1, p2, p3, p4];
  }
}
