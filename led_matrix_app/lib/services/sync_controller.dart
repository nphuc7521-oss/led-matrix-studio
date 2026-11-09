import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/board.dart';
import 'huidu_protocol.dart';
import 'wifi_service.dart';

class SyncController extends ChangeNotifier {
  List<LedBoard> boards = LedBoard.defaultBoards();
  int currentBoardIndex = 0;
  bool isSyncing = false;
  String currentStatus = 'Sẵn sàng điều khiển';
  String currentConnectedWifi = '';
  String currentLanguage = 'vi'; // 'vi' (Tiếng Việt) hoặc 'th' (ภาษาไทย)
  double progress = 0.0;
  List<String> logs = [
    '[KHỞI ĐỘNG] HD2020 LED Studio V18 Pro sẵn sàng.',
    'Hỗ trợ điều khiển 3 bảng LED ma trận HUB75 độc lập (Tiếng Việt & ภาษาไทย).'
  ];

  Timer? _wifiCheckTimer;

  SyncController() {
    _startWifiChecker();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      currentLanguage = prefs.getString('app_language') ?? 'vi';
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setLanguage(String lang) async {
    if (lang != currentLanguage) {
      currentLanguage = lang;
      notifyListeners();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('app_language', lang);
      } catch (_) {}
    }
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

  void updateCurrentBoardDimensions(int width, int height) {
    currentBoard.width = width;
    currentBoard.height = height;
    addLog('📐 Cập nhật độ phân giải ${currentBoard.name}: ${width}x$height px');
    notifyListeners();
  }

  void updateBoard(int index, LedBoard updated) {
    if (index >= 0 && index < boards.length) {
      boards[index] = updated;
      notifyListeners();
    }
  }

  void addLog(String msg) {
    debugPrint(msg);
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
        allowFallbackToCurrentWifi: true,
      );

      if (sent) {
        addLog(
          '===> [THÀNH CÔNG] ${board.name} đã lưu và hiển thị chữ "${board.text}"!',
        );
      } else {
        addLog(
          '[HƯỚNG DẪN] Chưa nhận được phản hồi từ ${board.name}. Hãy vào Cài đặt Wi-Fi -> Kết nối vào "${board.ssid}" (MK: 88888888) rồi bấm Nạp lại!',
        );
        await WifiService.openWifiSettings();
      }

      // Giải phóng kết nối Wi-Fi tạm thời của card để điện thoại tự động quay về mạng Wi-Fi tổng ban đầu
      await WifiService.disconnectWifi(board.ssid);

      isSyncing = false;
      notifyListeners();
      return sent;
    } catch (e) {
      addLog('[LỖI NGOẠI LỆ] $e');
      await WifiService.disconnectWifi('');
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
          addLog(
            '===> [XONG BẢNG ${i + 1}] ${board.name} đã hiển thị chữ "${board.text}"!',
          );
        } else {
          addLog('[CẢNH BÁO] Chưa nạp được ${board.name} (${board.ssid}).');
        }
      } catch (e) {
        addLog('  [LỖI BẢNG ${i + 1}] $e');
      }

      // Không gọi disconnectWifi giữa các bảng (i < total - 1) để tránh Android tự động nhảy về mạng tổng (Van Phong) giữa chừng gây kẹt khi chuyển sang Bảng 2!
      progress = (i + 1) / total;
      notifyListeners();
      if (i < total - 1) {
        await Future.delayed(const Duration(milliseconds: 250));
      }
    }

    // Sau khi đồng bộ xong cả 3 bảng, ngắt liên kết tạm thời với card WF2 để điện thoại tự động quay về mạng Wi-Fi tổng (ví dụ: Van Phong)
    addLog('>>> [MẠNG TỔNG] Đang trả kết nối điện thoại về mạng Wi-Fi chính...');
    await WifiService.disconnectWifi('');
    await Future.delayed(const Duration(milliseconds: 400));

    isSyncing = false;
    addLog('==============================================');
    if (successCount == total) {
      addLog('=== [HOÀN TẤT ĐỒNG BỘ CẢ 3 BẢNG THÀNH CÔNG (3/3)!] ===');
    } else {
      addLog('=== [ĐỒNG BỘ XONG] Thành công $successCount/$total bảng. ===');
      if (successCount < total) {
        addLog(
          '💡 Mẹo: Khi hộp thoại kết nối Wi-Fi hiện lên, hãy bấm "Kết nối", hoặc chọn từng Bảng (1, 2, 3) -> Bấm "NẠP RIÊNG BẢNG NÀY"!',
        );
      }
    }
    notifyListeners();
    return successCount == total;
  }
}
