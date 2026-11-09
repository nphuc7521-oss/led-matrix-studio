import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/board.dart';
import '../services/sync_controller.dart';
import '../services/huidu_protocol.dart';
import '../services/app_translations.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _textController;
  late AnimationController _animController;
  final ScrollController _logScrollController = ScrollController();
  bool _isSimPaused = false;

  List<Map<String, dynamic>> _getColors(String lang) {
    final bool isTh = lang == 'th';
    return [
      {'name': isTh ? 'เขียว' : 'Xanh Lá', 'id': 'green', 'color': const Color(0xFF00E676)},
      {'name': isTh ? 'แดง' : 'Đỏ', 'id': 'red', 'color': const Color(0xFFFF3333)},
      {'name': isTh ? 'เหลือง' : 'Vàng', 'id': 'yellow', 'color': const Color(0xFFFFEB3B)},
      {'name': isTh ? 'น้ำเงิน' : 'Xanh Dương', 'id': 'blue', 'color': const Color(0xFF2979FF)},
      {'name': isTh ? 'ฟ้าคราม' : 'Xanh Ngọc', 'id': 'cyan', 'color': const Color(0xFF00E5FF)},
      {'name': isTh ? 'ชมพูม่วง' : 'Hồng Tím', 'id': 'magenta', 'color': const Color(0xFFF50057)},
      {'name': isTh ? 'ขาว' : 'Trắng', 'id': 'white', 'color': const Color(0xFFFFFFFF)},
    ];
  }

  List<Map<String, dynamic>> _getRainbowPresets(String lang) {
    final bool isTh = lang == 'th';
    return [
      {'id': 0, 'name': isTh ? '🚫 สีเดียว' : '🚫 Đơn sắc'},
      {'id': 1, 'name': isTh ? '🌈 สายรุ้ง 1' : '🌈 Cầu Vồng 1'},
      {'id': 2, 'name': isTh ? '🌈 สายรุ้ง 2' : '🌈 Cầu Vồng 2'},
      {'id': 3, 'name': isTh ? '🌈 สายรุ้ง 3' : '🌈 Cầu Vồng 3'},
      {'id': 4, 'name': isTh ? '🔥 ไฟ แดง-เหลือง' : '🔥 Lửa Đỏ Vàng'},
      {'id': 5, 'name': isTh ? '🌊 มหาสมุทร' : '🌊 Đại Dương'},
      {'id': 6, 'name': isTh ? '🌆 อาทิตย์อัสดง' : '🌆 Hoàng Hôn'},
      {'id': 7, 'name': isTh ? '⚡ คลื่นนีออน' : '⚡ Neon Sóng'},
      {'id': 8, 'name': isTh ? '🔮 ไซเบอร์พังก์' : '🔮 Cyberpunk'},
    ];
  }

  List<Map<String, dynamic>> _getEffects(String lang) {
    final bool isTh = lang == 'th';
    return [
      {'name': isTh ? '⬅ เลื่อนไปทางซ้าย (Move Left)' : '⬅ Chạy sang trái (Move Left)', 'id': 1},
      {'name': isTh ? '➡ เลื่อนไปทางขวา (Move Right)' : '➡ Chạy sang phải (Move Right)', 'id': 2},
      {'name': isTh ? '⬆ เลื่อนขึ้นบน (Pull Up)' : '⬆ Cuộn lên trên (Pull Up)', 'id': 37},
      {'name': isTh ? '⬇ เลื่อนลงล่าง (Pull Down)' : '⬇ Cuộn xuống dưới (Pull Down)', 'id': 36},
      {'name': isTh ? '↕ ขยายแนวตั้ง 2 ทิศทาง' : '↕ Kéo giãn dọc 2 chiều', 'id': 38},
      {'name': isTh ? '↔ ขยายแนวนอน 2 ทิศทาง' : '↔ Kéo giãn ngang 2 chiều', 'id': 39},
      {'name': isTh ? '↔ แยกออกจากตรงกลาง' : '↔ Mở từ giữa ra 2 bên', 'id': 11},
      {'name': isTh ? '❄ หิมะตก (Snow)' : '❄ Tuyết rơi (Snow)', 'id': 28},
      {'name': isTh ? '✨ กระพริบ (Twinkle)' : '✨ Nhấp nháy (Twinkle)', 'id': 34},
      {'name': isTh ? '⏩ วิ่งต่อเนื่องไม่หยุด' : '⏩ Chạy liên tục không dừng', 'id': 202},
      {'name': isTh ? '⏹ หยุดนิ่ง (Immediate)' : '⏹ Đứng yên tĩnh (Immediate)', 'id': 0},
    ];
  }

  List<Map<String, dynamic>> _getBorders(String lang) {
    final bool isTh = lang == 'th';
    return [
      {'name': isTh ? 'แบบ 001 (จุด แดง-เหลือง-เขียว)' : 'Mẫu 001 (Chấm bi Đỏ - Vàng - Lục)', 'id': 1},
      {'name': isTh ? 'แบบ 002 (ดาวระยิบระยับ ขาว-ฟ้า)' : 'Mẫu 002 (Sao lấp lánh Trắng - Xanh)', 'id': 2},
      {'name': isTh ? 'แบบ 003 (คลื่น 7 สีต่อเนื่อง)' : 'Mẫu 003 (Sóng 7 màu liên tục)', 'id': 3},
      {'name': isTh ? 'แบบ 004 (หลากสี แดง-เขียว-น้ำเงิน)' : 'Mẫu 004 (Viền đa sắc Đỏ - Lục - Lam)', 'id': 4},
      {'name': isTh ? 'แบบ 005 (เพชร ม่วง-ฟ้า)' : 'Mẫu 005 (Kim cương Tím - Xanh ngọc)', 'id': 5},
      {'name': isTh ? 'แบบ 006 (เส้นนีออน เหลือง-แดง)' : 'Mẫu 006 (Đường gạch neon Vàng - Đỏ)', 'id': 6},
      {'name': isTh ? 'แบบ 007 (ดาวตก เขียว-เหลือง)' : 'Mẫu 007 (Vệt sao băng Xanh - Vàng)', 'id': 7},
    ];
  }

  final List<String> _fontFamilies = [
    'Arial',
    'Tahoma',
    'Segoe UI',
    'Consolas',
    'Times New Roman',
  ];

  final List<int> _fontSizes = [10, 12, 14, 16, 18, 20];

  SimTextMask? _currentMask;
  String _lastMaskKey = '';
  final Map<String, SimTextMask> _maskCache = {};

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    final controller = context.read<SyncController>();
    _textController = TextEditingController(text: controller.currentBoard.text);
    _checkAndUpdateMask(controller.currentBoard);
  }

  @override
  void dispose() {
    _textController.dispose();
    _animController.dispose();
    _logScrollController.dispose();
    super.dispose();
  }

  void _syncTextFromBoard(LedBoard b) {
    if (_textController.text != b.text) {
      _textController.text = b.text;
    }
  }

  void _checkAndUpdateMask(LedBoard b) {
    final key =
        '${b.id}_${b.text}_${b.fontSize}_${b.bold}_${b.italic}_${b.underline}_${b.borderStyle > 0}_${b.width}x${b.height}';
    if (key != _lastMaskKey) {
      _lastMaskKey = key;
      if (_maskCache.containsKey(key)) {
        _currentMask = _maskCache[key];
        return;
      }
      SimTextMask.generate(
        text: b.text,
        fontSize: b.fontSize,
        bold: b.bold,
        italic: b.italic,
        underline: b.underline,
        hasBorder: b.borderStyle > 0,
        width: b.width,
        height: b.height,
      ).then((mask) {
        if (_maskCache.length > 30) {
          _maskCache.clear();
        }
        _maskCache[key] = mask;
        if (mounted && _lastMaskKey == key) {
          setState(() {
            _currentMask = mask;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final syncController = context.watch<SyncController>();
    final currentBoard = syncController.currentBoard;
    final lang = syncController.currentLanguage;
    _syncTextFromBoard(currentBoard);
    _checkAndUpdateMask(currentBoard);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        elevation: 2,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: const Color(0xFF182234),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF06B6D4).withOpacity(0.4)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.flash_on, color: Color(0xFF06B6D4), size: 18),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SKYART LED STUDIO',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 0.8,
                    color: Color(0xFFF8FAFC),
                  ),
                ),
                Text(
                  syncController.currentConnectedWifi.isNotEmpty
                      ? '🟢 Wi-Fi: ${syncController.currentConnectedWifi}'
                      : (lang == 'th' ? '📡 พร้อมควบคุม SkyArt V18' : '📡 Sẵn sàng điều khiển SkyArt V18'),
                  style: TextStyle(
                    fontSize: 10,
                    color: syncController.currentConnectedWifi.isNotEmpty
                        ? const Color(0xFF10B981)
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Nút chuyển đổi nhanh ngôn ngữ Việt / Thái
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF182234),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF06B6D4).withOpacity(0.5)),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                final nextLang = lang == 'vi' ? 'th' : 'vi';
                syncController.setLanguage(nextLang);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      lang == 'vi' ? '🇻🇳 VI' : '🇹🇭 TH',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF06B6D4),
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.swap_horiz, size: 13, color: Color(0xFF06B6D4)),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: AppTranslations.tr('wifi_tooltip', lang),
            icon: const Icon(Icons.wifi_find, color: Color(0xFF06B6D4)),
            onPressed: () {
              syncController.openSystemWifiPanel();
            },
          ),
          IconButton(
            tooltip: AppTranslations.tr('settings_title', lang),
            icon: const Icon(Icons.settings, color: Color(0xFF94A3B8)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. THANH CHỌN BẢNG LED (3 TABS BẢNG 1, 2, 3)
                  _buildBoardSelector(syncController, lang),

                  const SizedBox(height: 12),

                  // 2. MÔ PHỎNG MÀN HÌNH LED (ĐỘ PHÂN GIẢI ĐỘNG)
                  _buildSimulatorSection(currentBoard, lang),

                  const SizedBox(height: 14),

                  // 3. CẤU HÌNH ĐỘ PHÂN GIẢI BẢNG LED (THỊ TRƯỜNG & TÙY CHỈNH)
                  _buildResolutionSection(syncController, currentBoard, lang),

                  const SizedBox(height: 14),

                  // 4. SOẠN THẢO VĂN BẢN (TYPOGRAPHY & TEXT)
                  _buildTypographySection(syncController, currentBoard, lang),

                  const SizedBox(height: 14),

                  // 5. HIỆU ỨNG CHUYỂN ĐỘNG & TỐC ĐỘ (MOTION)
                  _buildMotionSection(syncController, currentBoard, lang),

                  const SizedBox(height: 14),

                  // 6. VIỀN CHẠY ĐỘC LẬP (RUN BORDER)
                  _buildRunBorderSection(syncController, currentBoard, lang),

                  const SizedBox(height: 14),

                  // 7. NHẬT KÝ ĐIỀU KHIỂN (CONSOLE LOGS)
                  _buildLogsSection(syncController, lang),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // 7. THANH NẠP STICKY DƯỚI CÙNG
          _buildBottomStickyBar(syncController, currentBoard, lang),
        ],
      ),
    );
  }

  // =========================================================================
  // 1. THANH CHỌN BẢNG LED
  // =========================================================================
  Widget _buildBoardSelector(SyncController sync, String lang) {
    return Row(
      children: List.generate(sync.boards.length, (idx) {
        final b = sync.boards[idx];
        final isSelected = idx == sync.currentBoardIndex;
        return Expanded(
          child: GestureDetector(
            onTap: () => sync.selectBoard(idx),
            child: Container(
              margin: EdgeInsets.only(right: idx < 2 ? 6 : 0),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF182234) : const Color(0xFF111827),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? const Color(0xFF06B6D4) : const Color(0xFF243248),
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF06B6D4).withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : [],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? const Color(0xFF06B6D4) : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        b.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? const Color(0xFFF8FAFC) : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    b.ssid.replaceFirst('WF2_', ''),
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontFamily: 'Consolas',
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF06B6D4).withOpacity(0.15)
                          : const Color(0xFF1F2937),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${b.width} × ${b.height}',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? const Color(0xFF06B6D4) : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    b.text.isEmpty ? (lang == 'th' ? '(ว่าง)' : '(Trống)') : b.text,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  // =========================================================================
  // 2. MÔ PHỎNG MÀN HÌNH LED 64x32
  // =========================================================================
  Widget _buildSimulatorSection(LedBoard b, String lang) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF243248)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.tv, size: 14, color: Color(0xFF06B6D4)),
                  const SizedBox(width: 6),
                  Text(
                    '${AppTranslations.tr('sim_title', lang)}: ${b.name} (${b.width} × ${b.height} px)',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF8FAFC),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isSimPaused = !_isSimPaused;
                    if (_isSimPaused) {
                      _animController.stop();
                    } else {
                      _animController.repeat();
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF182234),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF33435E)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isSimPaused ? Icons.play_arrow : Icons.pause,
                        size: 12,
                        color: const Color(0xFF06B6D4),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isSimPaused ? AppTranslations.tr('sim_play', lang) : AppTranslations.tr('sim_pause', lang),
                        style: const TextStyle(fontSize: 10, color: Color(0xFF06B6D4)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // KHUNG MÀN HÌNH LED VỚI ỐC VÍT 4 GÓC (Tự co giãn tỷ lệ theo độ phân giải)
          Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double maxBoxW = min(constraints.maxWidth, 330.0);
                final double screenRatio = b.width / b.height;
                double simW = maxBoxW;
                double simH = (simW / screenRatio).clamp(70.0, 220.0);
                if (screenRatio < 1.0) {
                  simH = 200.0;
                  simW = (simH * screenRatio).clamp(100.0, maxBoxW);
                }

                return Container(
                  width: simW,
                  height: simH,
                  decoration: BoxDecoration(
                    color: const Color(0xFF06070A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF33435E), width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.6),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // 4 Ốc vít ở 4 góc
                      _buildScrew(top: 4, left: 4),
                      _buildScrew(top: 4, right: 4),
                      _buildScrew(bottom: 4, left: 4),
                      _buildScrew(bottom: 4, right: 4),

                      // Màn hình chấm LED CustomPaint
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: AnimatedBuilder(
                            animation: _animController,
                            builder: (context, _) {
                              return CustomPaint(
                                painter: LedSimulatorPainter(
                                  board: b,
                                  animProgress: _isSimPaused ? 0.5 : _animController.value,
                                  mask: _currentMask,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),
          // Floating badge tóm tắt
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF182234),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  '⚡ ${b.width} × ${b.height}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF06B6D4),
                  ),
                ),
                Text(
                  '${AppTranslations.tr('badge_effect', lang)}: ${_getEffectName(b.effect, lang)}',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                ),
                Text(
                  b.borderStyle > 0
                      ? '${AppTranslations.tr('badge_border_on', lang)} (${lang == 'th' ? 'แบบ' : 'Mẫu'} ${b.borderStyle})'
                      : AppTranslations.tr('badge_border_off', lang),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: b.borderStyle > 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrew({double? top, double? bottom, double? left, double? right}) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF64748B),
          border: Border.all(color: const Color(0xFF33435E), width: 0.8),
        ),
      ),
    );
  }

  // =========================================================================
  // 3. CẤU HÌNH ĐỘ PHÂN GIẢI BẢNG LED (RESOLUTION CHO TỪNG BẢNG HOẶC TẤT CẢ)
  // =========================================================================
  Widget _buildResolutionSection(SyncController sync, LedBoard b, String lang) {
    final standardPresets = [
      {'label': '64 × 32 px (1 tấm P4/P5)', 'w': 64, 'h': 32},
      {'label': '96 × 32 px (1.5 tấm P5 / 3 tấm P10)', 'w': 96, 'h': 32},
      {'label': '128 × 32 px (2 tấm P4/P5 ngang)', 'w': 128, 'h': 32},
      {'label': '160 × 32 px (5 tấm P10)', 'w': 160, 'h': 32},
      {'label': '192 × 32 px (3 tấm P4/P5 ngang)', 'w': 192, 'h': 32},
      {'label': '256 × 32 px (4 tấm P4/P5 ngang)', 'w': 256, 'h': 32},
      {'label': '320 × 32 px (5 tấm P4/P5 ngang)', 'w': 320, 'h': 32},
      {'label': '64 × 16 px (2 tấm P10)', 'w': 64, 'h': 16},
      {'label': '96 × 16 px (3 tấm P10)', 'w': 96, 'h': 16},
      {'label': '128 × 16 px (4 tấm P10)', 'w': 128, 'h': 16},
      {'label': '160 × 16 px (5 tấm P10)', 'w': 160, 'h': 16},
      {'label': '192 × 16 px (6 tấm P10)', 'w': 192, 'h': 16},
      {'label': '256 × 16 px (8 tấm P10)', 'w': 256, 'h': 16},
      {'label': '64 × 64 px (2 tấm vuông P4/P5)', 'w': 64, 'h': 64},
      {'label': '128 × 64 px (4 tấm P4/P5: 2×2)', 'w': 128, 'h': 64},
      {'label': '192 × 64 px (6 tấm P4/P5: 3×2)', 'w': 192, 'h': 64},
      {'label': '256 × 64 px (8 tấm P4/P5: 4×2)', 'w': 256, 'h': 64},
    ];

    final currentKey = '${b.width}x${b.height}';
    final bool isKnownPreset =
        standardPresets.any((p) => '${p['w']}x${p['h']}' == currentKey);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF243248)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.aspect_ratio, size: 14, color: Color(0xFF06B6D4)),
                  const SizedBox(width: 6),
                  Text(
                    '${AppTranslations.tr('res_title', lang)}: ${b.name}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF8FAFC),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => _showCustomResolutionDialog(context, sync, b, lang),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF182234),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFF06B6D4).withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.edit, size: 11, color: Color(0xFF06B6D4)),
                      const SizedBox(width: 4),
                      Text(
                        AppTranslations.tr('res_btn_custom', lang),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF06B6D4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Dropdown chọn nhanh các kích cỡ phổ biến
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF182234),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF243248)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: isKnownPreset ? currentKey : 'custom',
                isExpanded: true,
                dropdownColor: const Color(0xFF182234),
                style: const TextStyle(fontSize: 11.5, color: Color(0xFFF8FAFC)),
                items: [
                  ...standardPresets.map((p) {
                    final key = '${p['w']}x${p['h']}';
                    return DropdownMenuItem(
                      value: key,
                      child: Text('${p['label']}'),
                    );
                  }),
                  DropdownMenuItem(
                    value: 'custom',
                    child: Text(
                      isKnownPreset
                          ? AppTranslations.tr('res_custom_dropdown', lang)
                          : (lang == 'th'
                              ? '⚙ กำหนดเอง: ${b.width} × ${b.height} px'
                              : '⚙ Tùy chỉnh: ${b.width} × ${b.height} px'),
                      style: const TextStyle(
                        color: Color(0xFF06B6D4),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                onChanged: (val) {
                  if (val == null) return;
                  if (val == 'custom') {
                    _showCustomResolutionDialog(context, sync, b, lang);
                  } else {
                    final parts = val.split('x');
                    final nw = int.tryParse(parts[0]) ?? 64;
                    final nh = int.tryParse(parts[1]) ?? 32;
                    _maskCache.clear();
                    sync.updateCurrentBoardDimensions(nw, nh);
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Các nút chọn nhanh (Quick chips)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickResolutionChip(sync, b, 64, 32, '64×32'),
                _buildQuickResolutionChip(sync, b, 96, 32, '96×32'),
                _buildQuickResolutionChip(sync, b, 128, 32, '128×32'),
                _buildQuickResolutionChip(sync, b, 160, 32, '160×32'),
                _buildQuickResolutionChip(sync, b, 192, 32, '192×32'),
                _buildQuickResolutionChip(sync, b, 256, 32, '256×32'),
                _buildQuickResolutionChip(sync, b, 64, 16, '64×16'),
                _buildQuickResolutionChip(sync, b, 96, 16, '96×16'),
                _buildQuickResolutionChip(sync, b, 128, 16, '128×16'),
                _buildQuickResolutionChip(sync, b, 64, 64, '64×64'),
                _buildQuickResolutionChip(sync, b, 128, 64, '128×64'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickResolutionChip(
    SyncController sync,
    LedBoard b,
    int w,
    int h,
    String label,
  ) {
    final bool isSelected = b.width == w && b.height == h;
    return GestureDetector(
      onTap: () {
        _maskCache.clear();
        sync.updateCurrentBoardDimensions(w, h);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF06B6D4).withOpacity(0.2)
              : const Color(0xFF182234),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? const Color(0xFF06B6D4) : const Color(0xFF33435E),
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? const Color(0xFF06B6D4) : const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }

  void _showCustomResolutionDialog(
    BuildContext context,
    SyncController sync,
    LedBoard b,
    String lang,
  ) {
    final wCtrl = TextEditingController(text: b.width.toString());
    final hCtrl = TextEditingController(text: b.height.toString());

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111827),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFF243248)),
          ),
          title: Row(
            children: [
              const Icon(Icons.tune, color: Color(0xFF06B6D4), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${AppTranslations.tr('res_dialog_title', lang)} (${b.name})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppTranslations.tr('res_dialog_desc', lang),
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: wCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        labelText: AppTranslations.tr('res_dialog_width', lang),
                        labelStyle: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                        ),
                        suffixText: 'px',
                        suffixStyle: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                        ),
                        filled: true,
                        fillColor: const Color(0xFF182234),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF33435E)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '×',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: hCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        labelText: AppTranslations.tr('res_dialog_height', lang),
                        labelStyle: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                        ),
                        suffixText: 'px',
                        suffixStyle: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                        ),
                        filled: true,
                        fillColor: const Color(0xFF182234),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF33435E)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: Text(
                  AppTranslations.tr('res_dialog_hint', lang),
                  style: const TextStyle(fontSize: 10, color: Color(0xFF06B6D4)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                AppTranslations.tr('res_dialog_cancel', lang),
                style: const TextStyle(color: Color(0xFF94A3B8)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF06B6D4),
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                final nw = int.tryParse(wCtrl.text.trim()) ?? b.width;
                final nh = int.tryParse(hCtrl.text.trim()) ?? b.height;
                if (nw > 0 && nh > 0) {
                  _maskCache.clear();
                  sync.updateCurrentBoardDimensions(nw, nh);
                }
                Navigator.pop(ctx);
              },
              child: Text(
                AppTranslations.tr('res_dialog_save_single', lang),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () {
                final nw = int.tryParse(wCtrl.text.trim()) ?? b.width;
                final nh = int.tryParse(hCtrl.text.trim()) ?? b.height;
                if (nw > 0 && nh > 0) {
                  _maskCache.clear();
                  for (int i = 0; i < sync.boards.length; i++) {
                    sync.boards[i].width = nw;
                    sync.boards[i].height = nh;
                  }
                  sync.notifyListeners();
                  sync.addLog(
                    lang == 'th'
                        ? '📐 ปรับใช้ ${nw}x$nh px กับทุกบอร์ดเรียบร้อยแล้ว!'
                        : '📐 Đã áp dụng ${nw}x$nh px cho tất cả các bảng!',
                  );
                }
                Navigator.pop(ctx);
              },
              child: Text(
                AppTranslations.tr('res_dialog_save_all', lang),
                style: const TextStyle(color: Color(0xFF10B981), fontSize: 11),
              ),
            ),
          ],
        );
      },
    );
  }

  // =========================================================================
  // 4. SOẠN THẢO VĂN BẢN (TYPOGRAPHY)
  // =========================================================================
  Widget _buildTypographySection(SyncController sync, LedBoard b, String lang) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF243248)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.text_fields, size: 14, color: Color(0xFF06B6D4)),
              const SizedBox(width: 6),
              Text(
                '${AppTranslations.tr('typo_title', lang)}: ${b.name}',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFF8FAFC),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // HÀNG 1: FONT FAMILY & FONT SIZE & B/I/U
          Row(
            children: [
              // Font Family
              Expanded(
                flex: 3,
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF182234),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF243248)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: b.fontFamily,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF182234),
                      style: const TextStyle(fontSize: 11, color: Color(0xFFF8FAFC)),
                      items: _fontFamilies.map((f) {
                        return DropdownMenuItem(value: f, child: Text(f));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) sync.updateCurrentBoardFont(fontFamily: val);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Font Size
              Expanded(
                flex: 2,
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF182234),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF243248)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: b.fontSize,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF182234),
                      style: const TextStyle(fontSize: 11, color: Color(0xFFF8FAFC)),
                      items: _fontSizes.map((s) {
                        return DropdownMenuItem(value: s, child: Text('$s px'));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) sync.updateCurrentBoardFont(fontSize: val);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Nút Đậm (B), Nghiêng (I), Gạch Chân (U)
              _buildToggleBtn(
                label: 'B',
                active: b.bold,
                onTap: () => sync.updateCurrentBoardFont(bold: !b.bold),
              ),
              const SizedBox(width: 4),
              _buildToggleBtn(
                label: 'I',
                active: b.italic,
                onTap: () => sync.updateCurrentBoardFont(italic: !b.italic),
              ),
              const SizedBox(width: 4),
              _buildToggleBtn(
                label: 'U',
                active: b.underline,
                onTap: () => sync.updateCurrentBoardFont(underline: !b.underline),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // HÀNG 2: CĂN LỀ & MÀU CHỮ & NÚT 7 MÀU [AB]
          Row(
            children: [
              // Căn lề trái / giữa / phải
              _buildAlignBtn(icon: Icons.format_align_left, align: 'left', current: b.alignH, sync: sync),
              const SizedBox(width: 4),
              _buildAlignBtn(icon: Icons.format_align_center, align: 'center', current: b.alignH, sync: sync),
              const SizedBox(width: 4),
              _buildAlignBtn(icon: Icons.format_align_right, align: 'right', current: b.alignH, sync: sync),

              const SizedBox(width: 8),

              // Nút [AB] 7 MÀU RAINBOW
              GestureDetector(
                onTap: () => _showRainbowPicker(context, sync, b, lang),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFF0000),
                        Color(0xFFFFFF00),
                        Color(0xFF00FF00),
                        Color(0xFF00FFFF),
                        Color(0xFF0000FF),
                        Color(0xFFFF00FF),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: b.colorfulWords > 0 ? Colors.white : Colors.transparent,
                      width: 1.5,
                    ),
                    boxShadow: b.colorfulWords > 0
                        ? [
                            BoxShadow(
                              color: const Color(0xFF06B6D4).withOpacity(0.5),
                              blurRadius: 6,
                            )
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        b.colorfulWords > 0
                            ? '✓ ${AppTranslations.tr('typo_rainbow_btn', lang)}'
                            : AppTranslations.tr('typo_rainbow_btn', lang),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          shadows: [Shadow(color: Colors.black, blurRadius: 2)],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // 7 Dấu chấm màu sắc đơn sắc
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _getColors(lang).map((c) {
                    final isAct = b.colorfulWords == 0 && b.color == c['id'];
                    return GestureDetector(
                      onTap: () {
                        sync.updateCurrentBoardColor(c['id'], 0);
                      },
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: c['color'] as Color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isAct ? Colors.white : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: isAct
                              ? [
                                  BoxShadow(
                                    color: (c['color'] as Color).withOpacity(0.6),
                                    blurRadius: 6,
                                  )
                                ]
                              : [],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Ô NHẬP NỘI DUNG CHỮ
          TextField(
            controller: _textController,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFFF8FAFC),
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: AppTranslations.tr('typo_text_hint', lang),
              hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              filled: true,
              fillColor: const Color(0xFF182234),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF243248)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF243248)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF06B6D4)),
              ),
            ),
            onChanged: (val) {
              sync.updateCurrentBoardText(val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToggleBtn({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? const Color(0xFF06B6D4) : const Color(0xFF182234),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF243248)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: active ? Colors.black : const Color(0xFFF8FAFC),
          ),
        ),
      ),
    );
  }

  Widget _buildAlignBtn({
    required IconData icon,
    required String align,
    required String current,
    required SyncController sync,
  }) {
    final active = current == align;
    return GestureDetector(
      onTap: () => sync.updateCurrentBoardFont(alignH: align),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: active ? const Color(0xFF06B6D4).withOpacity(0.2) : const Color(0xFF182234),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: active ? const Color(0xFF06B6D4) : const Color(0xFF243248),
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: active ? const Color(0xFF06B6D4) : const Color(0xFF94A3B8),
        ),
      ),
    );
  }

  void _showRainbowPicker(BuildContext context, SyncController sync, LedBoard b, String lang) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '🌈 ${AppTranslations.tr('typo_rainbow_btn', lang)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF8FAFC),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Color(0xFF94A3B8)),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _getRainbowPresets(lang).map((rp) {
                  final active = b.colorfulWords == rp['id'];
                  return GestureDetector(
                    onTap: () {
                      sync.updateCurrentBoardColor(b.color, rp['id'] as int);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? const Color(0xFF06B6D4).withOpacity(0.2) : const Color(0xFF182234),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: active ? const Color(0xFF06B6D4) : const Color(0xFF243248),
                        ),
                      ),
                      child: Text(
                        rp['name'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: active ? FontWeight.bold : FontWeight.normal,
                          color: active ? const Color(0xFF06B6D4) : const Color(0xFFF8FAFC),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // =========================================================================
  // 5. HIỆU ỨNG CHUYỂN ĐỘNG & TỐC ĐỘ (MOTION)
  // =========================================================================
  Widget _buildMotionSection(SyncController sync, LedBoard b, String lang) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF243248)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.slow_motion_video, size: 14, color: Color(0xFF06B6D4)),
              const SizedBox(width: 6),
              Text(
                AppTranslations.tr('motion_title', lang),
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFF8FAFC),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Chọn hiệu ứng dropdown
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF182234),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF243248)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: b.effect,
                isExpanded: true,
                dropdownColor: const Color(0xFF182234),
                style: const TextStyle(fontSize: 11.5, color: Color(0xFFF8FAFC)),
                items: _getEffects(lang).map((e) {
                  return DropdownMenuItem(
                    value: e['id'] as int,
                    child: Text(e['name'] as String),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) sync.updateCurrentBoardEffect(val);
                },
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Thanh kéo Tốc độ & Thời gian dừng
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${AppTranslations.tr('motion_speed_label', lang)}: ${b.speed}',
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      ),
                      child: Slider(
                        value: b.speed.toDouble(),
                        min: 1,
                        max: 20,
                        divisions: 19,
                        activeColor: const Color(0xFF06B6D4),
                        inactiveColor: const Color(0xFF243248),
                        onChanged: (val) {
                          sync.updateCurrentBoardEffect(b.effect, speed: val.toInt());
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${AppTranslations.tr('motion_stay_label', lang)}: ${b.stayTime} ${lang == 'th' ? 'วินาที' : 'giây'}',
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      ),
                      child: Slider(
                        value: b.stayTime.toDouble(),
                        min: 0,
                        max: 10,
                        divisions: 10,
                        activeColor: const Color(0xFF10B981),
                        inactiveColor: const Color(0xFF243248),
                        onChanged: (val) {
                          sync.updateCurrentBoardEffect(b.effect, stayTime: val.toInt());
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Badge ClearType chuẩn 201
          Row(
            children: [
              const Icon(Icons.check_circle, size: 12, color: Color(0xFF10B981)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  lang == 'th'
                      ? 'Do not clear (Clear=201) ข้อความไหลลื่นไม่กระพริบดำ'
                      : 'Do not clear (Clear=201) giúp chữ chạy mượt không chớp đen',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF10B981), fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 6. VIỀN CHẠY ĐỘC LẬP (RUN BORDER)
  // =========================================================================
  Widget _buildRunBorderSection(SyncController sync, LedBoard b, String lang) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF243248)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.crop_square, size: 14, color: Color(0xFF06B6D4)),
                  const SizedBox(width: 6),
                  Text(
                    AppTranslations.tr('border_title', lang),
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF8FAFC),
                    ),
                  ),
                ],
              ),
              Switch(
                value: b.borderStyle > 0,
                activeColor: const Color(0xFF06B6D4),
                onChanged: (enabled) {
                  sync.updateCurrentBoardBorder(
                    borderStyle: enabled ? 1 : 0,
                  );
                },
              ),
            ],
          ),

          if (b.borderStyle > 0) ...[
            const SizedBox(height: 8),

            // Chọn mẫu viền 001..007
            Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF182234),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF243248)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: b.borderStyle,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF182234),
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFFF8FAFC)),
                  items: _getBorders(lang).map((br) {
                    return DropdownMenuItem(
                      value: br['id'] as int,
                      child: Text(br['name'] as String),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      sync.updateCurrentBoardBorder(borderStyle: val);
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Hướng chạy viền & Tốc độ viền
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text('${AppTranslations.tr('border_dir', lang)}: ', style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8))),
                      ChoiceChip(
                        label: Text(lang == 'th' ? 'ตามเข็ม (CW)' : 'Thuận (CW)', style: const TextStyle(fontSize: 10)),
                        selected: b.borderMode == 'Clockwise',
                        selectedColor: const Color(0xFF06B6D4),
                        onSelected: (s) {
                          if (s) sync.updateCurrentBoardBorder(borderStyle: b.borderStyle, borderMode: 'Clockwise');
                        },
                      ),
                      const SizedBox(width: 4),
                      ChoiceChip(
                        label: Text(lang == 'th' ? 'ทวนเข็ม' : 'Ngược', style: const TextStyle(fontSize: 10)),
                        selected: b.borderMode != 'Clockwise',
                        selectedColor: const Color(0xFF06B6D4),
                        onSelected: (s) {
                          if (s) sync.updateCurrentBoardBorder(borderStyle: b.borderStyle, borderMode: 'Anti-clockwise');
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // =========================================================================
  // 7. NHẬT KÝ ĐIỀU KHIỂN & CONSOLE
  // =========================================================================
  Widget _buildLogsSection(SyncController sync, String lang) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF243248)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.terminal, size: 14, color: Color(0xFF06B6D4)),
                  const SizedBox(width: 6),
                  Text(
                    AppTranslations.tr('logs_title', lang),
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF8FAFC),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => sync.clearLogs(),
                child: Text(
                  AppTranslations.tr('logs_clear', lang),
                  style: const TextStyle(fontSize: 10, color: Color(0xFF06B6D4)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Container(
            height: 130,
            decoration: BoxDecoration(
              color: const Color(0xFF06070A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF1F2D44)),
            ),
            padding: const EdgeInsets.all(8),
            child: ListView.builder(
              controller: _logScrollController,
              itemCount: sync.logs.length,
              itemBuilder: (context, idx) {
                final log = sync.logs[idx];
                Color c = const Color(0xFF94A3B8);
                if (log.contains('[THÀNH CÔNG]')) c = const Color(0xFF10B981);
                if (log.contains('[LỖI]')) c = const Color(0xFFEF4444);
                if (log.contains('[CẢNH BÁO]')) c = const Color(0xFFF59E0B);
                if (log.contains('[ACK OK]')) c = const Color(0xFF06B6D4);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    log,
                    style: TextStyle(
                      fontFamily: 'Consolas',
                      fontSize: 10,
                      color: c,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 8. THANH NẠP STICKY DƯỚI CÙNG
  // =========================================================================
  Widget _buildBottomStickyBar(SyncController sync, LedBoard b, String lang) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Color(0xFF111827),
        border: Border(top: BorderSide(color: Color(0xFF243248))),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // NÚT 1: GỬI ĐỒNG BỘ CẢ 3 BẢNG (TỰ ĐỘNG CHUYỂN WIFI)
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF06B6D4),
                  foregroundColor: Colors.black,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: sync.isSyncing
                    ? null
                    : () async {
                        await sync.syncAllBoards();
                      },
                child: sync.isSyncing
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            AppTranslations.tr('btn_syncing', lang),
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                          ),
                        ],
                      )
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.bolt, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              '⚡ ${AppTranslations.tr('btn_sync_all', lang)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 12.5,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 8),

            // NÚT 2: NẠP RIÊNG BẢNG NÀY (BẢNG ĐANG KẾT NỐI WI-FI)
            SizedBox(
              width: double.infinity,
              height: 38,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF10B981),
                  side: const BorderSide(color: Color(0xFF10B981), width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: sync.isSyncing
                    ? null
                    : () async {
                        await sync.syncCurrentBoardDirect();
                      },
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_tethering, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '📡 ${AppTranslations.tr('btn_sync_single', lang)} ${b.name} (${b.ssid})',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getEffectName(int eff, String lang) {
    final match = _getEffects(lang).firstWhere(
      (e) => e['id'] == eff,
      orElse: () => {'name': lang == 'th' ? 'เอฟเฟกต์ $eff' : 'Hiệu ứng $eff'},
    );
    return match['name'] as String;
  }
}

// =========================================================================
// MẶT NẠ CHẤM LED MA TRẬN (SIM TEXT MASK 64x32)
// =========================================================================
class SimTextMask {
  final int width;
  final int height;
  final List<bool> pixels;
  final int litCount;

  SimTextMask({
    required this.width,
    required this.height,
    required this.pixels,
    this.litCount = 0,
  });

  bool get hasLitPixels => litCount > 0;

  bool isLit(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) return false;
    return pixels[y * width + x];
  }

  static Future<SimTextMask> generate({
    required String text,
    required int fontSize,
    required bool bold,
    required bool italic,
    required bool underline,
    bool hasBorder = true,
    int width = 64,
    int height = 32,
  }) async {
    final tight = await HuiduProtocol.renderTightTextMask(
      text: text,
      fontSize: fontSize,
      bold: bold,
      italic: italic,
      underline: underline,
      hasBorder: hasBorder,
      width: width,
      height: height,
    );
    return SimTextMask(
      width: tight.width,
      height: tight.height,
      pixels: tight.pixels,
      litCount: tight.litCount,
    );
  }
}

// =========================================================================
// CUSTOM PAINTER: MÔ PHỎNG CHẤM LED MA TRẬN ĐỘ PHÂN GIẢI ĐỘNG CHUẨN XÁC 100% NHƯ WEB V18
// =========================================================================
class LedSimulatorPainter extends CustomPainter {
  final LedBoard board;
  final double animProgress;
  final SimTextMask? mask;

  LedSimulatorPainter({
    required this.board,
    required this.animProgress,
    this.mask,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final int cols = board.width;
    final int rows = board.height;

    final dotWidth = size.width / cols;
    final dotHeight = size.height / rows;
    final radius = min(dotWidth, dotHeight) * 0.42;

    // Palette viền 7 mẫu chuẩn xác 100% như Web V18 (có các điểm ngắt null tạo hiệu ứng lấp lánh/chấm bi)
    final borderPaletteMap = <int, List<Color?>>{
      1: [
        const Color(0xFFFF0000), const Color(0xFFFF0000), null,
        const Color(0xFFFFEB3B), const Color(0xFFFFEB3B), null,
        const Color(0xFF00E676), const Color(0xFF00E676), null,
      ],
      2: [Colors.white, const Color(0xFF00E5FF), null, const Color(0xFF00E5FF)],
      3: [
        const Color(0xFFFF0000), const Color(0xFFFF0000),
        const Color(0xFFFFEB3B), const Color(0xFFFFEB3B),
        const Color(0xFF00E676), const Color(0xFF00E676),
        const Color(0xFF00E5FF), const Color(0xFF00E5FF),
        const Color(0xFF2979FF), const Color(0xFF2979FF),
        const Color(0xFFF50057), const Color(0xFFF50057),
      ],
      4: [
        const Color(0xFFFF0000), const Color(0xFFFF0000), const Color(0xFFFF0000), null,
        const Color(0xFF00E676), const Color(0xFF00E676), const Color(0xFF00E676), null,
        const Color(0xFF2979FF), const Color(0xFF2979FF), const Color(0xFF2979FF), null,
      ],
      5: [
        const Color(0xFFF50057), const Color(0xFFF50057), const Color(0xFFF50057), null,
        const Color(0xFF00E5FF), const Color(0xFF00E5FF), const Color(0xFF00E5FF), null,
      ],
      6: [
        const Color(0xFFFFEB3B), const Color(0xFFFFEB3B), const Color(0xFFFFEB3B), null,
        const Color(0xFFFF3333), const Color(0xFFFF3333), const Color(0xFFFF3333), null,
      ],
      7: [
        const Color(0xFF00E676), const Color(0xFF00E676), const Color(0xFF00E676),
        const Color(0xFFFFEB3B), const Color(0xFFFFEB3B), null,
      ],
    };

    final Map<int, Color> borderColors = {};
    if (board.borderStyle > 0) {
      final borderPalette = borderPaletteMap[board.borderStyle] ?? borderPaletteMap[1]!;
      final cw = board.borderMode != 'Anti-clockwise';
      final bTick = (animProgress * 60).toInt();
      final perimeterPixels = (cols + (rows - 2)) * 2;

      for (int pos = 0; pos < perimeterPixels; pos++) {
        int bx = 0, by = 0;
        if (pos < cols) {
          bx = pos;
          by = 0;
        } else if (pos < cols + (rows - 2)) {
          bx = cols - 1;
          by = 1 + (pos - cols);
        } else if (pos < cols + (rows - 2) + cols) {
          bx = (cols - 1) - (pos - (cols + rows - 2));
          by = rows - 1;
        } else {
          bx = 0;
          by = (rows - 2) - (pos - (cols * 2 + rows - 2));
        }

        final shiftedPos = cw
            ? (pos + bTick) % perimeterPixels
            : (perimeterPixels + pos - (bTick % perimeterPixels)) % perimeterPixels;
        final c = borderPalette[shiftedPos % borderPalette.length];
        if (c != null) {
          borderColors[by * cols + bx] = c;
        }
      }
    }

    // Tính toán vị trí drawX, drawY của chữ dựa trên hiệu ứng chuyển động
    final eff = board.effect;
    final textW = mask?.width ?? 30;
    final textH = mask?.height ?? 18;

    int startX = (cols - textW) ~/ 2;
    if (board.alignH == 'left') startX = 3;
    else if (board.alignH == 'right') startX = cols - textW - 3;

    int baselineY = (rows - textH) ~/ 2;
    if (board.alignV == 'top') baselineY = 2;
    else if (board.alignV == 'bottom') baselineY = rows - textH - 2;

    int drawX = startX;
    int drawY = baselineY;
    bool isVisible = true;

    if (eff == 1) { // Chạy sang trái (Move Left)
      if (animProgress < 0.35) {
        final t = animProgress / 0.35;
        drawX = (cols + (startX - cols) * t).round();
      } else if (animProgress < 0.70) {
        drawX = startX; // Dừng tại giữa bảng
      } else {
        final t = (animProgress - 0.70) / 0.30;
        drawX = (startX + (-textW - startX) * t).round();
      }
    } else if (eff == 2) { // Chạy sang phải (Move Right)
      if (animProgress < 0.35) {
        final t = animProgress / 0.35;
        drawX = (-textW + (startX - (-textW)) * t).round();
      } else if (animProgress < 0.70) {
        drawX = startX;
      } else {
        final t = (animProgress - 0.70) / 0.30;
        drawX = (startX + (cols - startX) * t).round();
      }
    } else if (eff == 37 || eff == 3) { // Kéo lên (Pull Up)
      if (animProgress < 0.35) {
        final t = animProgress / 0.35;
        drawY = (rows + (baselineY - rows) * t).round();
      } else if (animProgress < 0.70) {
        drawY = baselineY;
      } else {
        final t = (animProgress - 0.70) / 0.30;
        drawY = (baselineY + (-textH - baselineY) * t).round();
      }
    } else if (eff == 36 || eff == 4) { // Kéo xuống (Pull Down)
      if (animProgress < 0.35) {
        final t = animProgress / 0.35;
        drawY = (-textH + (baselineY - (-textH)) * t).round();
      } else if (animProgress < 0.70) {
        drawY = baselineY;
      } else {
        final t = (animProgress - 0.70) / 0.30;
        drawY = (baselineY + (rows - baselineY) * t).round();
      }
    } else if (eff == 202) { // Chạy liên tục sang trái
      final totalDist = cols + textW;
      drawX = (cols - (animProgress * totalDist)).round();
    } else if (eff == 34) { // Nhấp nháy
      isVisible = (animProgress * 8).toInt() % 2 == 0;
    }

    final darkLedPaint = Paint()..color = const Color(0xFF141720);
    final baseColor = HuiduProtocol.parseColor(board.color);
    final isRainbow = board.colorfulWords > 0;

    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        final cx = x * dotWidth + dotWidth / 2;
        final cy = y * dotHeight + dotHeight / 2;
        final isBorderPixel = (x == 0 || x == cols - 1 || y == 0 || y == rows - 1);

        if (board.borderStyle > 0 && isBorderPixel) {
          final bColor = borderColors[y * cols + x];
          if (bColor != null) {
            final paint = Paint()
              ..color = bColor
              ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2.0);
            canvas.drawCircle(Offset(cx, cy), radius, paint);
          } else {
            canvas.drawCircle(Offset(cx, cy), radius, darkLedPaint);
          }
          continue;
        }

        // Chấm LED bên trong ma trận
        bool isLit = false;
        if (isVisible && mask != null && board.text.trim().isNotEmpty) {
          final srcX = x - drawX;
          final srcY = y - drawY;
          isLit = mask!.isLit(srcX, srcY);
        }

        if (isLit) {
          Color dotColor;
          if (isRainbow) {
            final hue = (x / cols * 360.0 + animProgress * 360.0) % 360.0;
            dotColor = HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor();
          } else {
            dotColor = baseColor;
          }
          final litPaint = Paint()
            ..color = dotColor
            ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 1.5);
          canvas.drawCircle(Offset(cx, cy), radius, litPaint);
        } else {
          canvas.drawCircle(Offset(cx, cy), radius, darkLedPaint);
        }
      }
    }

    // Dự phòng an toàn 100%: Nếu mask chưa sẵn sàng hoặc rỗng, vẽ chữ trực tiếp phát sáng
    if ((mask == null || !mask!.hasLitPixels) && isVisible && board.text.trim().isNotEmpty) {
      final fallbackColor = isRainbow ? const Color(0xFF00E5FF) : baseColor;
      final tp = TextPainter(
        text: TextSpan(
          text: board.text.trim(),
          style: TextStyle(
            color: fallbackColor,
            fontSize: size.height * 0.45,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(
                color: fallbackColor.withOpacity(0.8),
                blurRadius: 10,
              ),
            ],
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width - 16);

      final offset = Offset(
        (size.width - tp.width) / 2,
        (size.height - tp.height) / 2,
      );
      tp.paint(canvas, offset);
    }
  }

  @override
  bool shouldRepaint(covariant LedSimulatorPainter oldDelegate) {
    return true;
  }
}