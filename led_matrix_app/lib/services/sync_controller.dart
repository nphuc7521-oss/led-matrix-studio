import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/board.dart';
import 'huidu_protocol.dart';
import 'wifi_service.dart';

class SyncController extends ChangeNotifier {
  List<LedBoard> boards = LedBoard.defaultBoards();
  int currentBoardIndex = 0;
  bool isSyncing = false;
  String currentStatus = 'Sẵn sàng điều khiển';
  String currentConnectedWifi = '';
  double progress = 0.0;
  List<String> logs = [
    '[KHỞI ĐỘNG] HD2020 LED Studio Pro sẵn sàng.',
    'Hỗ trợ điều khiển 3 bảng LED ma trận HUB75 64x32 độc lập.'
  ];

  Timer? _wifiCheckTimer;

  SyncController() {
    _startWifiChecker();
  }

  @override
  void dispose() {
    _wifiCheckTimer?.cancel();
    super.dispose();
  }

  void _startWifiChecker() {
    _wifiCheckTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final ssid = await WifiService.getCurrentWifiSsid();
      if (ssid != currentConnectedWifi) {
        currentConnectedWifi = ssid;
        notifyListeners();
      }
    });
  }

  LedBoard get currentBoard => boards[currentBoardIndex];

  void selectBoard(int index) {
    if (index >= 0 && index < boards.length) {
      currentBoardIndex = index;
      notifyListeners();
    }
  }

  void updateCurrentBoardText(String text) {
    currentBoard.text = text;
    notifyListeners();
  }

  void updateCurrentBoardColor(String color, int colorfulWords) {
    currentBoard.color = color;
    currentBoard.colorfulWords = colorfulWords;
    notifyListeners();
  }

  void updateCurrentBoardFont({
    String? fontFamily,
    int? fontSize,
    bool? bold,
    bool? italic,
    bool? underline,
    String? alignH,
  }) {
    if (fontFamily != null) currentBoard.fontFamily = fontFamily;
    if (fontSize != null) currentBoard.fontSize = fontSize;
    if (bold != null) currentBoard.bold = bold;
    if (italic != null) currentBoard.italic = italic;
    if (underline != null) currentBoard.underline = underline;
    if (alignH != null) currentBoard.alignH = alignH;
    notifyListeners();
  }

  void updateCurrentBoardEffect(int effect, {int? speed, int? stayTime}) {
    currentBoard.effect = effect;
    if (speed != null) currentBoard.speed = speed;
    if (stayTime != null) currentBoard.stayTime = stayTime;
    notifyListeners();
  }

  void updateCurrentBoardBorder({
    required int borderStyle,
    int? borderSpeed,
    String? borderMode,
  }) {
    currentBoard.borderStyle = borderStyle;
    if (borderSpeed != null) currentBoard.borderSpeed = borderSpeed;
    if (borderMode != null) currentBoard.borderMode = borderMode;
    notifyListeners();
  }

  void updateBoard(int index, LedBoard updated) {
    if (index >= 0 && index < boards.length) {
      boards[index] = updated;
      notifyListeners();
    }
  }

  void addLog(String msg) {
    logs.add(msg);
    if (logs.length > 80) logs.removeAt(0);
    currentStatus = msg;
    notifyListeners();
  }

  void clearLogs() {
    logs.clear();
    addLog('[ĐÃ XÓA NHẬT KÝ] Sẵn sàng điều khiển.');
  }

  /// Nạp trực tiếp cho 1 bảng cụ thể (Đang chọn hoặc chỉ định)
  Future<bool> syncCurrentBoardDirect() async {
    if (isSyncing) return false;
    isSyncing = true;
    final board = currentBoard;
    addLog('==============================================');
    addLog('>>> [NẠP TRỰC TIẾP] ${board.name} (${board.ssid})...');
    addLog('    Nội dung: "${board.text}" | Chữ: ${board.color.toUpperCase()} | Font: ${board.fontSize}px');

    try {
      addLog('  [RENDER] Đang kết xuất hình ảnh chữ Tiếng Việt sang 3 Plane RGB...');
      final packets = await HuiduProtocol.generateBoardPackets(board);

      final sent = await WifiService.sendPacketsToBoard(
        ip: board.ip,
        port: board.port,
        packets: packets,
        onLog: (l) => addLog(l),
      );

      if (sent) {
        addLog('===> [THÀNH CÔNG] ${board.name} đã hiển thị chữ mới thành công!');
      } else {
        addLog('[LỖI] Không thể gửi tới ${board.ip}:${board.port}.');
        addLog('  * Gợi ý: Hãy kiểm tra chắc chắn điện thoại đã kết nối Wi-Fi "${board.ssid}"!');
      }

      isSyncing = false;
      notifyListeners();
      return sent;
    } catch (e) {
      addLog('[LỖI NGOẠI LỆ] $e');
      isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  /// Nạp tuần tự cho cả 3 bảng LED (Có đổi Wi-Fi giữa các card)
  Future<bool> syncAllBoards() async {
    if (isSyncing) return false;
    isSyncing = true;
    progress = 0.0;
    addLog('==============================================');
    addLog('>>> BẮT ĐẦU ĐỒNG BỘ CẢ 3 BẢNG LED MA TRẬN...');

    int successCount = 0;
    final total = boards.length;

    for (int i = 0; i < total; i++) {
      final board = boards[i];
      addLog('----------------------------------------------');
      addLog('>>> [${i + 1}/$total] NẠP ${board.name} (SSID: ${board.ssid})...');
      addLog('    Chữ: "${board.text}" | Hiệu ứng: ${board.effect} | Viền: Mẫu ${board.borderStyle}');

      try {
        final packets = await HuiduProtocol.generateBoardPackets(board);

        final success = await WifiService.updateSingleBoard(
          board: board,
          packets: packets,
          onStatus: (msg) {
            addLog(msg);
          },
        );

        if (success) {
          successCount++;
          addLog('===> [XONG BẢNG ${i + 1}] ${board.name} đã nhận dữ liệu!');
        } else {
          addLog('[CẢNH BÁO] Không thể nạp ${board.name}.');
        }
      } catch (e) {
        addLog('  [LỖI BẢNG ${i + 1}] $e');
      }

      progress = (i + 1) / total;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 600));
    }

    isSyncing = false;
    addLog('==============================================');
    if (successCount == total) {
      addLog('=== [HOÀN TẤT ĐỒNG BỘ CẢ 3 BẢNG THÀNH CÔNG (3/3)!] ===');
    } else {
      addLog('=== [ĐỒNG BỘ XONG] Thành công $successCount/$total bảng. ===');
      if (successCount < total) {
        addLog('💡 Mẹo: Bạn có thể chọn từng tab bảng và bấm "NẠP RIÊNG BẢNG NÀY" sau khi kết nối Wi-Fi tương ứng.');
      }
    }
    notifyListeners();
    return successCount == total;
  }
}
