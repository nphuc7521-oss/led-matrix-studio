import 'package:flutter/foundation.dart';
import '../models/board.dart';
import 'huidu_protocol.dart';
import 'wifi_service.dart';

class SyncController extends ChangeNotifier {
  List<LedBoard> boards = LedBoard.defaultBoards();
  int currentBoardIndex = 0;
  bool isSyncing = false;
  String currentStatus = 'Sẵn sàng điều khiển';
  double progress = 0.0;
  List<String> logs = [
    '[KHỞI ĐỘNG] HD2020 Studio Mobile sẵn sàng.',
    'Nhập nội dung cho 3 bảng và nhấn GỬI ĐỒNG BỘ.'
  ];

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

  void updateCurrentBoardEffect(int effect) {
    currentBoard.effect = effect;
    notifyListeners();
  }

  void updateCurrentBoardBorder(int borderStyle) {
    currentBoard.borderStyle = borderStyle;
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
    if (logs.length > 50) logs.removeAt(0);
    currentStatus = msg;
    notifyListeners();
  }

  Future<bool> syncCurrentBoardDirect() async {
    if (isSyncing) return false;
    isSyncing = true;
    final board = currentBoard;
    addLog('>>> BẮT ĐẦU NẠP TRỰC TIẾP CHO ${board.name}...');
    addLog('  (Đảm bảo điện thoại đã kết nối WiFi: ${board.ssid})');

    final packets = HuiduProtocol.generateBoardPackets(board);
    final sent = await WifiService.sendPacketsToBoard(
      ip: board.ip,
      port: board.port,
      packets: packets,
    );

    if (sent) {
      addLog('===> [THÀNH CÔNG] ${board.name} đã nhận chữ: "${board.text}"!');
    } else {
      addLog('[LỖI] Không thể gửi tới ${board.ip}:${board.port}. Hãy kiểm tra WiFi!');
    }

    isSyncing = false;
    notifyListeners();
    return sent;
  }

  Future<bool> syncAllBoards() async {
    if (isSyncing) return false;
    isSyncing = true;
    progress = 0.0;
    addLog('==============================================');
    addLog('>>> BẮT ĐẦU ĐỒNG BỘ 3 BẢNG LED MA TRẬN...');

    int successCount = 0;
    final total = boards.length;

    for (int i = 0; i < total; i++) {
      final board = boards[i];
      addLog('>>> [${i + 1}/$total] Đang kết nối ${board.name} (${board.ssid})...');

      final packets = HuiduProtocol.generateBoardPackets(board);

      final success = await WifiService.updateSingleBoard(
        board: board,
        packets: packets,
        onStatus: (msg) {
          addLog(msg);
        },
      );

      if (success) {
        successCount++;
        addLog('===> [THÀNH CÔNG] ${board.name} đã nhận chữ: "${board.text}"!');
      } else {
        addLog('[CẢNH BÁO] Không thể nạp ${board.name}');
      }

      progress = (i + 1) / total;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 600));
    }

    isSyncing = false;
    if (successCount == total) {
      addLog('==============================================');
      addLog('=== [HOÀN TẤT ĐỒNG BỘ CẢ 3 BẢNG THÀNH CÔNG!] ===');
    } else {
      addLog('=== [ĐỒNG BỘ XONG] Thành công $successCount/$total bảng. ===');
    }
    notifyListeners();
    return successCount == total;
  }
}
