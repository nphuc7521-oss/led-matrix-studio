import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/board.dart';
import '../services/sync_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final syncController = context.watch<SyncController>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('CÀI ĐẶT 3 BẢNG LED'),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: syncController.boards.length,
        itemBuilder: (context, index) {
          final board = syncController.boards[index];
          return _buildBoardEditor(context, syncController, index, board);
        },
      ),
    );
  }

  Widget _buildBoardEditor(
    BuildContext context,
    SyncController controller,
    int index,
    LedBoard board,
  ) {
    final ssidController = TextEditingController(text: board.ssid);
    final pwdController = TextEditingController(text: board.password);

    return Card(
      color: const Color(0xFF1E293B),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.developer_board, color: Colors.cyanAccent),
                const SizedBox(width: 8),
                Text(
                  board.name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ssidController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Tên WiFi (SSID)',
                labelStyle: TextStyle(color: Colors.grey),
                prefixIcon: Icon(Icons.wifi, color: Colors.grey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: pwdController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Mật khẩu WiFi',
                labelStyle: TextStyle(color: Colors.grey),
                prefixIcon: Icon(Icons.lock, color: Colors.grey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent.shade700),
                icon: const Icon(Icons.save, size: 18),
                label: const Text('Lưu bảng này'),
                onPressed: () {
                  final updated = LedBoard(
                    id: board.id,
                    name: board.name,
                    ssid: ssidController.text.trim(),
                    password: pwdController.text.trim(),
                    ip: board.ip,
                    port: board.port,
                    guid: board.guid,
                  );
                  controller.updateBoard(index, updated);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã cập nhật ${board.name}!')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
