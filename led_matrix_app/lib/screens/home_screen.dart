import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/board.dart';
import '../services/sync_controller.dart';
import '../services/huidu_protocol.dart';
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

  final List<Map<String, dynamic>> _colors = [
    {'name': 'Xanh Lá', 'id': 'green', 'color': const Color(0xFF00E676)},
    {'name': 'Đỏ', 'id': 'red', 'color': const Color(0xFFFF3333)},
    {'name': 'Vàng', 'id': 'yellow', 'color': const Color(0xFFFFEB3B)},
    {'name': 'Xanh Dương', 'id': 'blue', 'color': const Color(0xFF2979FF)},
    {'name': 'Xanh Ngọc', 'id': 'cyan', 'color': const Color(0xFF00E5FF)},
    {'name': 'Hồng Tím', 'id': 'magenta', 'color': const Color(0xFFF50057)},
    {'name': 'Trắng', 'id': 'white', 'color': const Color(0xFFFFFFFF)},
  ];

  final List<Map<String, dynamic>> _rainbowPresets = [
    {'id': 0, 'name': '🚫 Đơn sắc'},
    {'id': 1, 'name': '🌈 Cầu Vồng 1'},
    {'id': 2, 'name': '🌈 Cầu Vồng 2'},
    {'id': 3, 'name': '🌈 Cầu Vồng 3'},
    {'id': 4, 'name': '🔥 Lửa Đỏ Vàng'},
    {'id': 5, 'name': '🌊 Đại Dương'},
    {'id': 6, 'name': '🌆 Hoàng Hôn'},
    {'id': 7, 'name': '⚡ Neon Sóng'},
    {'id': 8, 'name': '🔮 Cyberpunk'},
  ];

  final List<Map<String, dynamic>> _effects = [
    {'name': '⬅ Chạy sang trái (Move Left)', 'id': 1},
    {'name': '➡ Chạy sang phải (Move Right)', 'id': 2},
    {'name': '⬆ Cuộn lên trên (Pull Up)', 'id': 37},
    {'name': '⬇ Cuộn xuống dưới (Pull Down)', 'id': 36},
    {'name': '↕ Kéo giãn dọc 2 chiều', 'id': 38},
    {'name': '↔ Kéo giãn ngang 2 chiều', 'id': 39},
    {'name': '↔ Mở từ giữa ra 2 bên', 'id': 11},
    {'name': '❄ Tuyết rơi (Snow)', 'id': 28},
    {'name': '✨ Nhấp nháy (Twinkle)', 'id': 34},
    {'name': '⏩ Chạy liên tục không dừng', 'id': 202},
    {'name': '⏹ Đứng yên tĩnh (Immediate)', 'id': 0},
  ];

  final List<Map<String, dynamic>> _borders = [
    {'name': 'Mẫu 001 (Chấm bi Đỏ - Vàng - Lục)', 'id': 1},
    {'name': 'Mẫu 002 (Sao lấp lánh Trắng - Xanh)', 'id': 2},
    {'name': 'Mẫu 003 (Sóng 7 màu liên tục)', 'id': 3},
    {'name': 'Mẫu 004 (Viền đa sắc Đỏ - Lục - Lam)', 'id': 4},
    {'name': 'Mẫu 005 (Kim cương Tím - Xanh ngọc)', 'id': 5},
    {'name': 'Mẫu 006 (Đường gạch neon Vàng - Đỏ)', 'id': 6},
    {'name': 'Mẫu 007 (Vệt sao băng Xanh - Vàng)', 'id': 7},
  ];

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
    final key = '${b.id}_${b.text}_${b.fontSize}_${b.bold}_${b.italic}_${b.underline}';
    if (key != _lastMaskKey) {
      _lastMaskKey = key;
      SimTextMask.generate(
        text: b.text,
        fontSize: b.fontSize,
        bold: b.bold,
        italic: b.italic,
        underline: b.underline,
      ).then((mask) {
        if (mounted) {
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
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF06B6D4).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.flash_on, color: Color(0xFF06B6D4), size: 18),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'HD2020 LED STUDIO PRO',
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
                      : '📡 Sẵn sàng điều khiển Dark Studio V18',
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
          IconButton(
            tooltip: 'Chọn nhanh Wi-Fi Card LED',
            icon: const Icon(Icons.wifi_find, color: Color(0xFF06B6D4)),
            onPressed: () {
              syncController.openSystemWifiPanel();
            },
          ),
          IconButton(
            tooltip: 'Cài đặt SSID & Mật khẩu',
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
                  _buildBoardSelector(syncController),

                  const SizedBox(height: 12),

                  // 2. MÔ PHỎNG MÀN HÌNH LED 64x32
                  _buildSimulatorSection(currentBoard),

                  const SizedBox(height: 14),

                  // 3. SOẠN THẢO VĂN BẢN (TYPOGRAPHY & TEXT)
                  _buildTypographySection(syncController, currentBoard),

                  const SizedBox(height: 14),

                  // 4. HIỆU ỨNG CHUYỂN ĐỘNG & TỐC ĐỘ (MOTION)
                  _buildMotionSection(syncController, currentBoard),

                  const SizedBox(height: 14),

                  // 5. VIỀN CHẠY ĐỘC LẬP (RUN BORDER)
                  _buildRunBorderSection(syncController, currentBoard),

                  const SizedBox(height: 14),

                  // 6. NHẬT KÝ ĐIỀU KHIỂN (CONSOLE LOGS)
                  _buildLogsSection(syncController),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // 7. THANH NẠP STICKY DƯỚI CÙNG
          _buildBottomStickyBar(syncController, currentBoard),
        ],
      ),
    );
  }

  // =========================================================================
  // 1. THANH CHỌN BẢNG LED
  // =========================================================================
  Widget _buildBoardSelector(SyncController sync) {
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
                  Text(
                    b.text.isEmpty ? '(Trống)' : b.text,
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
  Widget _buildSimulatorSection(LedBoard b) {
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
                    'MÔ PHỎNG: ${b.name} (64 × 32 px)',
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
                        _isSimPaused ? 'Chạy' : 'Dừng',
                        style: const TextStyle(fontSize: 10, color: Color(0xFF06B6D4)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // KHUNG MÀN HÌNH LED VỚI ỐC VÍT 4 GÓC
          Center(
            child: Container(
              width: 320,
              height: 160,
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
                const Text(
                  '⚡ 64 × 32',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF06B6D4),
                  ),
                ),
                Text(
                  'Hiệu ứng: ${_getEffectName(b.effect)}',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                ),
                Text(
                  b.borderStyle > 0 ? 'Viền: BẬT (Mẫu ${b.borderStyle})' : 'Viền: TẮT',
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
  // 3. SOẠN THẢO VĂN BẢN (TYPOGRAPHY)
  // =========================================================================
  Widget _buildTypographySection(SyncController sync, LedBoard b) {
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
                'Nội Dung & Kiểu Chữ: ${b.name}',
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
                onTap: () => _showRainbowPicker(context, sync, b),
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
                        b.colorfulWords > 0 ? '✓ [AB] 7 MÀU' : '[AB] 7 MÀU',
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
                  children: _colors.map((c) {
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

          // Ô NHẬP NỘI DUNG CHỮ TIẾNG VIỆT
          TextField(
            controller: _textController,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFFF8FAFC),
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'Nhập nội dung chữ hiển thị lên LED...',
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

  void _showRainbowPicker(BuildContext context, SyncController sync, LedBoard b) {
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
                  const Text(
                    '🌈 Chọn Mẫu Chữ 7 Màu Rainbow [AB]',
                    style: TextStyle(
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
                children: _rainbowPresets.map((rp) {
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
  // 4. HIỆU ỨNG CHUYỂN ĐỘNG & TỐC ĐỘ (MOTION)
  // =========================================================================
  Widget _buildMotionSection(SyncController sync, LedBoard b) {
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
          const Row(
            children: [
              Icon(Icons.slow_motion_video, size: 14, color: Color(0xFF06B6D4)),
              SizedBox(width: 6),
              Text(
                'Hiệu Ứng Di Chuyển & Tốc Độ',
                style: TextStyle(
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
                items: _effects.map((e) {
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
                      'Tốc độ: ${b.speed} (1: Rất nhanh, 20: Chậm)',
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
                      'Dừng: ${b.stayTime} giây',
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
          const Row(
            children: [
              Icon(Icons.check_circle, size: 12, color: Color(0xFF10B981)),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Do not clear (Clear=201) giúp chữ chạy mượt không chớp đen',
                  style: TextStyle(fontSize: 10, color: Color(0xFF10B981), fontWeight: FontWeight.w600),
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
  // 5. VIỀN CHẠY ĐỘC LẬP (RUN BORDER)
  // =========================================================================
  Widget _buildRunBorderSection(SyncController sync, LedBoard b) {
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
              const Row(
                children: [
                  Icon(Icons.crop_square, size: 14, color: Color(0xFF06B6D4)),
                  SizedBox(width: 6),
                  Text(
                    'Viền Chạy Độc Lập 4 Cạnh (Run Border)',
                    style: TextStyle(
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
                  items: _borders.map((br) {
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
                      const Text('Hướng: ', style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8))),
                      ChoiceChip(
                        label: const Text('Thuận (CW)', style: TextStyle(fontSize: 10)),
                        selected: b.borderMode == 'Clockwise',
                        selectedColor: const Color(0xFF06B6D4),
                        onSelected: (s) {
                          if (s) sync.updateCurrentBoardBorder(borderStyle: b.borderStyle, borderMode: 'Clockwise');
                        },
                      ),
                      const SizedBox(width: 4),
                      ChoiceChip(
                        label: const Text('Ngược', style: TextStyle(fontSize: 10)),
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
  // 6. NHẬT KÝ ĐIỀU KHIỂN & CONSOLE
  // =========================================================================
  Widget _buildLogsSection(SyncController sync) {
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
              const Row(
                children: [
                  Icon(Icons.terminal, size: 14, color: Color(0xFF06B6D4)),
                  SizedBox(width: 6),
                  Text(
                    'Nhật Ký Truyền Dữ Liệu (Console)',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF8FAFC),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => sync.clearLogs(),
                child: const Text(
                  'Xóa nhật ký',
                  style: TextStyle(fontSize: 10, color: Color(0xFF06B6D4)),
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
  // 7. THANH NẠP STICKY DƯỚI CÙNG
  // =========================================================================
  Widget _buildBottomStickyBar(SyncController sync, LedBoard b) {
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
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'ĐANG NẠP DỮ LIỆU...',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                          ),
                        ],
                      )
                    : const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bolt, size: 18),
                            SizedBox(width: 6),
                            Text(
                              '⚡ GỬI ĐỒNG BỘ CẢ 3 BẢNG (AUTO SYNC)',
                              style: TextStyle(
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
                        '📡 NẠP RIÊNG ${b.name} (${b.ssid})',
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

  String _getEffectName(int eff) {
    final match = _effects.firstWhere(
      (e) => e['id'] == eff,
      orElse: () => {'name': 'Hiệu ứng $eff'},
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
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) {
      return SimTextMask(width: 1, height: 1, pixels: [false], litCount: 0);
    }

    // Tự động scale font để chiều cao chữ lấp đầy ~18-24 chấm LED trong khung 32 dòng
    final double fs = (fontSize.clamp(10, 24) * 1.15);

    final style = TextStyle(
      color: Colors.white,
      fontSize: fs,
      fontWeight: bold ? FontWeight.w900 : FontWeight.bold,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      height: 1.0,
    );

    final tp = TextPainter(
      text: TextSpan(text: cleanText, style: style),
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
    );
    tp.layout();

    final int tw = max(1, tp.width.ceil());
    final int th = max(1, tp.height.ceil());

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, tw.toDouble(), th.toDouble()));
    tp.paint(canvas, Offset.zero);

    if (underline) {
      canvas.drawLine(
        Offset(0, th.toDouble() - 1),
        Offset(tw.toDouble(), th.toDouble() - 1),
        Paint()..color = Colors.white..strokeWidth = 2,
      );
    }

    final pic = recorder.endRecording();
    final img = await pic.toImage(tw, th);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    final bytes = byteData?.buffer.asUint8List() ?? Uint8List(0);

    final pixels = List<bool>.filled(tw * th, false);
    int lit = 0;
    if (bytes.isNotEmpty) {
      for (int y = 0; y < th; y++) {
        for (int x = 0; x < tw; x++) {
          final idx = (y * tw + x) * 4;
          if (idx + 3 < bytes.length) {
            final a = bytes[idx + 3];
            final r = bytes[idx];
            final g = bytes[idx + 1];
            final b = bytes[idx + 2];
            if (a > 30 || r > 50 || g > 50 || b > 50) {
              pixels[y * tw + x] = true;
              lit++;
            }
          }
        }
      }
    }

    return SimTextMask(width: tw, height: th, pixels: pixels, litCount: lit);
  }
}

// =========================================================================
// CUSTOM PAINTER: MÔ PHỎNG CHẤM LED MA TRẬN 64x32 CHUẨN XÁC 100% NHƯ WEB V18
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
    const int cols = 64;
    const int rows = 32;

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
      const perimeterPixels = (64 + 30) * 2; // 188 pixels

      for (int pos = 0; pos < perimeterPixels; pos++) {
        int bx = 0, by = 0;
        if (pos < 64) {
          bx = pos;
          by = 0;
        } else if (pos < 64 + 30) {
          bx = 63;
          by = 1 + (pos - 64);
        } else if (pos < 64 + 30 + 64) {
          bx = 63 - (pos - 94);
          by = 31;
        } else {
          bx = 0;
          by = 30 - (pos - 158);
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