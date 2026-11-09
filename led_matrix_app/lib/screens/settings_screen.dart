import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/board.dart';
import '../services/sync_controller.dart';
import '../services/app_translations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final syncController = context.watch<SyncController>();
    final lang = syncController.currentLanguage;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(AppTranslations.tr('settings_title', lang)),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. CHỌN NGÔN NGỮ (VIỆT NAM / THÁI LAN)
          _buildLanguageCard(context, syncController, lang),

          const SizedBox(height: 16),

          // 2. CÀI ĐẶT TỪNG BẢNG
          ...List.generate(syncController.boards.length, (index) {
            final board = syncController.boards[index];
            return _buildBoardEditor(context, syncController, index, board, lang);
          }),
        ],
      ),
    );
  }

  Widget _buildLanguageCard(
    BuildContext context,
    SyncController controller,
    String currentLang,
  ) {
    return Card(
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.language, color: Color(0xFF06B6D4)),
                const SizedBox(width: 8),
                Text(
                  AppTranslations.tr('settings_language', currentLang),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Nút Tiếng Việt
                Expanded(
                  child: GestureDetector(
                    onTap: () => controller.setLanguage('vi'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      decoration: BoxDecoration(
                        color: currentLang == 'vi'
                            ? const Color(0xFF06B6D4).withOpacity(0.2)
                            : const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: currentLang == 'vi'
                              ? const Color(0xFF06B6D4)
                              : const Color(0xFF33435E),
                          width: currentLang == 'vi' ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🇻🇳', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          Text(
                            'Tiếng Việt',
                            style: TextStyle(
                              color: currentLang == 'vi'
                                  ? const Color(0xFF06B6D4)
                                  : Colors.white70,
                              fontWeight: currentLang == 'vi'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Nút Tiếng Thái
                Expanded(
                  child: GestureDetector(
                    onTap: () => controller.setLanguage('th'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      decoration: BoxDecoration(
                        color: currentLang == 'th'
                            ? const Color(0xFF06B6D4).withOpacity(0.2)
                            : const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: currentLang == 'th'
                              ? const Color(0xFF06B6D4)
                              : const Color(0xFF33435E),
                          width: currentLang == 'th' ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🇹🇭', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          Text(
                            'ภาษาไทย',
                            style: TextStyle(
                              color: currentLang == 'th'
                                  ? const Color(0xFF06B6D4)
                                  : Colors.white70,
                              fontWeight: currentLang == 'th'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoardEditor(
    BuildContext context,
    SyncController controller,
    int index,
    LedBoard board,
    String lang,
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
              decoration: InputDecoration(
                labelText: AppTranslations.tr('settings_ssid', lang),
                labelStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.wifi, color: Colors.grey),
                enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: pwdController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: AppTranslations.tr('settings_pwd', lang),
                labelStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.lock, color: Colors.grey),
                enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent.shade700),
                icon: const Icon(Icons.save, size: 18),
                label: Text(AppTranslations.tr('settings_save', lang)),
                onPressed: () {
                  final updated = LedBoard(
                    id: board.id,
                    name: board.name,
                    ssid: ssidController.text.trim(),
                    password: pwdController.text.trim(),
                    ip: board.ip,
                    port: board.port,
                    guid: board.guid,
                    width: board.width,
                    height: board.height,
                  );
                  controller.updateBoard(index, updated);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppTranslations.tr('settings_updated', lang, {'name': board.name}),
                      ),
                    ),
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
