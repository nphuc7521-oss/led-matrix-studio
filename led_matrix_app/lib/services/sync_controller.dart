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
    '[KHỞI ĐỘNG] HD2020 LED Studio V18 Pro sẵn sàng.',
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
    _wifiCheckTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
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

  /// Mở nhanh cài đặt Wi-Fi của máy
  Future<void> openSystemWifiPanel() async {
    await WifiService.openWifiSettings();
  }

  /// Nạp trực tiếp cho 1 bảng đang chọn (Bắt buộc đúng Wi-Fi card đó để không làm tắt card khác)
  Future<bool> syncCurrentBoardDirect() async {
    if (isSyncing) return false;
    isSyncing = true;
    final board = currentBoard;
    addLog('==============================================');
    addLog('>>> [NẠP RIÊNG] ${board.name} (SSID: ${board.ssid})...');
    addLog(
      '    Nội dung: "${board.text}" | Chữ: ${board.colorfulWords > 0 ? "7 Màu [AB]" : board.color.toUpperCase()} | Viền: ${board.borderStyle > 0 ? "Mẫu ${board.borderStyle}" : "Tắt"}',
    );

    try {
      addLog('  [RENDER] Đang kết xuất hình ảnh chữ Tiếng Việt chuẩn HDSDK...');
      final packets = await HuiduProtocol.generateBoardPackets(board);

      final sent = await WifiService.updateSingleBoard(
        board: board,
        packets: packets,
        onStatus: (l) => addLog(l),
        allowFallbackToCurrentWifi: false,
      );

      if (sent) {
        addLog('===> [THÀNH CÔNG] ${board.name} đã hiển thị chữ "${board.text}"!');
      } else {
        addLog('[HƯỚNG DẪN] Đang mở danh sách Wi-Fi -> Chạm chọn Wi-Fi "${board.ssid}" (Mật khẩu: 88888888) rồi bấm Nạp lại!');
        await WifiService.openWifiSettings();
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

  /// Nạp tuần tự cho cả 3 bảng LED siêu tốc
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
      addLog(
        '    Chữ: "${board.text}" | Hiệu ứng: ${board.effect} | Viền: ${board.borderStyle > 0 ? "Mẫu ${board.borderStyle}" : "Tắt"}',
      );

      try {
        final packets = await HuiduProtocol.generateBoardPackets(board);

        final success = await WifiService.updateSingleBoard(
          board: board,
          packets: packets,
          onStatus: (msg) {
            addLog(msg);
          },
          allowFallbackToCurrentWifi: false,
        );

        if (success) {
          successCount++;
          addLog('===> [XONG BẢNG ${i + 1}] ${board.name} đã hiển thị chữ "${board.text}"!');
        } else {
          addLog('[CẢNH BÁO] Chưa nạp được ${board.name} (${board.ssid}).');
        }
      } catch (e) {
        addLog('  [LỖI BẢNG ${i + 1}] $e');
      }

      progress = (i + 1) / total;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 150));
    }

    isSyncing = false;
    addLog('==============================================');
    if (successCount == total) {
      addLog('=== [HOÀN TẤT ĐỒNG BỘ CẢ 3 BẢNG THÀNH CÔNG (3/3)!] ===');
    } else {
      addLog('=== [ĐỒNG BỘ XONG] Thành công $successCount/$total bảng. ===');
      if (successCount < total) {
        addLog('💡 Mẹo: Trên Android, bạn có thể chọn từng Bảng (Bảng 1, 2, 3) -> Kết nối Wi-Fi card đó -> Bấm "NẠP RIÊNG BẢNG NÀY" (chỉ 1 giây/bảng)!');
      }
    }
    notifyListeners();
    return successCount == total;
  }
}
