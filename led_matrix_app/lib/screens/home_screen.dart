import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/board.dart';
import '../services/sync_controller.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TextEditingController _textController;
  late AnimationController _animController;

  final List<Map<String, dynamic>> _colors = [
    {'name': 'Đỏ', 'id': 'red', 'color': const Color(0xFFFF0000)},
    {'name': 'Xanh Lá', 'id': 'green', 'color': const Color(0xFF00FF00)},
    {'name': 'Xanh Dương', 'id': 'blue', 'color': const Color(0xFF0088FF)},
    {'name': 'Vàng', 'id': 'yellow', 'color': const Color(0xFFFFFF00)},
    {'name': 'Xanh Lơ', 'id': 'cyan', 'color': const Color(0xFF00FFFF)},
    {'name': 'Hồng Tím', 'id': 'magenta', 'color': const Color(0xFFFF00FF)},
    {'name': 'Trắng', 'id': 'white', 'color': const Color(0xFFFFFFFF)},
  ];

  final List<Map<String, dynamic>> _effects = [
    {'name': '⬅ Chạy sang trái (Move Left)', 'id': 1},
    {'name': '➡ Chạy sang phải (Move Right)', 'id': 2},
    {'name': '⬆ Cuộn lên trên (Pull Up)', 'id': 37},
    {'name': '⬇ Cuộn xuống dưới (Pull Down)', 'id': 36},
    {'name': '↔ Kéo giãn sang hai bên (Stretch)', 'id': 39},
    {'name': '⏹ Đứng yên tĩnh (Immediate)', 'id': 0},
  ];

  final List<Map<String, dynamic>> _borders = [
    {'name': 'Tắt viền', 'id': 0},
    {'name': 'Mẫu 001 (Chấm đơn)', 'id': 1},
    {'name': 'Mẫu 002 (Hai chấm)', 'id': 2},
    {'name': 'Mẫu 003 (Đoạn gạch)', 'id': 3},
    {'name': 'Mẫu 004 (Sao lấp lánh)', 'id': 4},
    {'name': 'Mẫu 005 (Đường liền)', 'id': 5},
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    final controller = context.read<SyncController>();
    _textController = TextEditingController(text: controller.currentBoard.text);
  }

  @override
  void dispose() {
    _textController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _syncTextFromBoard(LedBoard b) {
    if (_textController.text != b.text) {
      _textController.text = b.text;
    }
  }

  @override
  Widget build(BuildContext context) {
    final syncController = context.watch<SyncController>();
    final currentBoard = syncController.currentBoard;
    _syncTextFromBoard(currentBoard);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 3,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.flash_on, color: Colors.cyanAccent, size: 20),
            const SizedBox(width: 6),
            const Text(
              'HD2020 LED STUDIO PRO',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                letterSpacing: 1.2,
                color: Colors.cyanAccent,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.cyanAccent),
            tooltip: 'Cài đặt kết nối WiFi',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Tab Chọn 3 Bảng
            _buildBoardTabs(syncController),

            const SizedBox(height: 12),

            // 2. Mô phỏng màn hình LED Matrix 64x32
            _buildLedMatrixSimulator(currentBoard),

            const SizedBox(height: 14),

            // 3. Khung Nhập Chữ Tiếng Việt
            _buildTextInputCard(syncController, currentBoard),

            const SizedBox(height: 12),

            // 4. Chọn Màu Sắc & Nút [AB] 7 Màu Cầu Vồng
            _buildColorSection(syncController, currentBoard),

            const SizedBox(height: 12),

            // 5. Hiệu Ứng Di Chuyển & Tốc Độ
            _buildEffectSection(syncController, currentBoard),

            const SizedBox(height: 12),

            // 6. Viền Chạy Độc Lập (Run Border)
            _buildBorderSection(syncController, currentBoard),

            const SizedBox(height: 18),

            // 7. Nút GỬI ĐỒNG BỘ CẢ 3 BẢNG (Sticky/Big Button)
            _buildSyncAction(syncController),

            const SizedBox(height: 14),

            // 8. Bảng Console Log Nhật Ký Truyền
            _buildConsoleLogs(syncController),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- 1. TAB CHỌN 3 BẢNG ---
  Widget _buildBoardTabs(SyncController sync) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blueGrey.shade800),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(sync.boards.length, (index) {
          final b = sync.boards[index];
          final isSelected = sync.currentBoardIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                sync.selectBoard(index);
                _textController.text = sync.boards[index].text;
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.cyanAccent.shade700 : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.cyanAccent.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          )
                        ]
                      : null,
                ),
                child: Column(
                  children: [
                    Text(
                      b.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isSelected ? Colors.white : Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      b.text.isEmpty ? '(Trống)' : b.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: isSelected ? Colors.white.withOpacity(0.9) : Colors.cyanAccent.shade200,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // --- 2. MÔ PHỎNG LED 64x32 SIMULATOR ---
  Widget _buildLedMatrixSimulator(LedBoard b) {
    Color textColor;
    switch (b.color.toLowerCase()) {
      case 'green':
        textColor = const Color(0xFF00FF00);
        break;
      case 'blue':
        textColor = const Color(0xFF0088FF);
        break;
      case 'yellow':
        textColor = const Color(0xFFFFFF00);
        break;
      case 'cyan':
        textColor = const Color(0xFF00FFFF);
        break;
      case 'magenta':
        textColor = const Color(0xFFFF00FF);
        break;
      case 'white':
        textColor = const Color(0xFFFFFFFF);
        break;
      default:
        textColor = const Color(0xFFFF0000);
    }

    final hasBorder = b.borderStyle > 0;
    final isRainbow = b.colorfulWords > 0;

    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasBorder ? Colors.amberAccent.shade400 : Colors.grey.shade800,
          width: hasBorder ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isRainbow ? Colors.purpleAccent : textColor).withOpacity(0.35),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Nền lưới LED matrix chấm li ti
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: CustomPaint(
                painter: _LedGridPainter(),
              ),
            ),
          ),
          // Chữ hiển thị
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: isRainbow
                  ? ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Colors.red,
                          Colors.orange,
                          Colors.yellow,
                          Colors.green,
                          Colors.cyan,
                          Colors.blue,
                          Colors.purple,
                        ],
                      ).createShader(bounds),
                      child: Text(
                        b.text.isEmpty ? 'CHƯA NHẬP CHỮ' : b.text,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                          color: Colors.white,
                          letterSpacing: 2.0,
                        ),
                      ),
                    )
                  : Text(
                      b.text.isEmpty ? 'CHƯA NHẬP CHỮ' : b.text,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                        color: textColor,
                        letterSpacing: 2.0,
                        shadows: [
                          Shadow(
                            color: textColor.withOpacity(0.85),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          // Nhãn góc hiển thị kích thước
          Positioned(
            bottom: 4,
            right: 8,
            child: Text(
              '64x32 HUB75 • ${b.name}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. KHUNG NHẬP CHỮ ---
  Widget _buildTextInputCard(SyncController sync, LedBoard b) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'NỘI DUNG CHỮ HIỂN THỊ (${b.name})',
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_textController.text.length} ký tự',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _textController,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: 'Nhập nội dung hiển thị (hỗ trợ Tiếng Việt)...',
              hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              filled: true,
              fillColor: const Color(0xFF0F172A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              suffixIcon: _textController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        setState(() {
                          _textController.clear();
                          sync.updateCurrentBoardText('');
                        });
                      },
                    )
                  : null,
            ),
            onChanged: (val) {
              setState(() {
                sync.updateCurrentBoardText(val);
              });
            },
          ),
        ],
      ),
    );
  }

  // --- 4. CHỌN MÀU & NÚT [AB] ---
  Widget _buildColorSection(SyncController sync, LedBoard b) {
    final isRainbow = b.colorfulWords > 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MÀU SẮC CHỮ HIỂN THỊ',
            style: TextStyle(
              color: Colors.cyanAccent,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Nút 7 Màu Gradient [AB]
              Expanded(
                flex: 4,
                child: GestureDetector(
                  onTap: () {
                    sync.updateCurrentBoardColor(b.color, isRainbow ? 0 : 1);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Colors.red,
                          Colors.orange,
                          Colors.yellow,
                          Colors.green,
                          Colors.cyan,
                          Colors.purple,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isRainbow ? Colors.white : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: isRainbow
                          ? [
                              BoxShadow(
                                color: Colors.purpleAccent.withOpacity(0.5),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        isRainbow ? '✔ 7 MÀU [AB] BẬT' : '✨ 7 MÀU [AB]',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          shadows: [
                            Shadow(color: Colors.black, blurRadius: 4),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Danh sách nút màu đơn sắc
              Expanded(
                flex: 6,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _colors.map((c) {
                      final isSelected = !isRainbow && b.color.toLowerCase() == c['id'];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3.0),
                        child: GestureDetector(
                          onTap: () {
                            sync.updateCurrentBoardColor(c['id'], 0);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: c['color'] as Color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.grey.shade800,
                                width: isSelected ? 3.0 : 1.0,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: (c['color'] as Color).withOpacity(0.6),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 5. HIỆU ỨNG & TỐC ĐỘ ---
  Widget _buildEffectSection(SyncController sync, LedBoard b) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HIỆU ỨNG DI CHUYỂN & TỐC ĐỘ',
            style: TextStyle(
              color: Colors.cyanAccent,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: b.effect,
            dropdownColor: const Color(0xFF1E293B),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF0F172A),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
            items: _effects
                .map((e) => DropdownMenuItem<int>(
                      value: e['id'] as int,
                      child: Text(e['name'] as String),
                    ))
                .toList(),
            onChanged: (val) {
              if (val != null) {
                sync.updateCurrentBoardEffect(val);
              }
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('Tốc độ: ', style: TextStyle(color: Colors.grey, fontSize: 13)),
              Text('${b.speed}', style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
              Expanded(
                child: Slider(
                  value: b.speed.toDouble(),
                  min: 1,
                  max: 20,
                  divisions: 19,
                  activeColor: Colors.cyanAccent,
                  inactiveColor: Colors.blueGrey.shade800,
                  onChanged: (val) {
                    setState(() {
                      b.speed = val.toInt();
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 6. VIỀN CHẠY ĐỘC LẬP (RUN BORDER) ---
  Widget _buildBorderSection(SyncController sync, LedBoard b) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'VIỀN CHẠY ĐỘC LẬP (RUN BORDER)',
                style: TextStyle(
                  color: Colors.amberAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Switch(
                value: b.borderStyle > 0,
                activeColor: Colors.amberAccent,
                onChanged: (val) {
                  sync.updateCurrentBoardBorder(val ? 1 : 0);
                },
              ),
            ],
          ),
          if (b.borderStyle > 0) ...[
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: b.borderStyle,
              dropdownColor: const Color(0xFF1E293B),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF0F172A),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
              items: _borders
                  .map((br) => DropdownMenuItem<int>(
                        value: br['id'] as int,
                        child: Text(br['name'] as String),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  sync.updateCurrentBoardBorder(val);
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  // --- 7. NÚT GỬI ĐỒNG BỘ 3 BẢNG ---
  Widget _buildSyncAction(SyncController sync) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 8,
        ),
        onPressed: sync.isSyncing
            ? null
            : () async {
                await sync.syncAllBoards();
              },
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: sync.isSyncing
                  ? [Colors.blueGrey.shade700, Colors.blueGrey.shade800]
                  : [const Color(0xFF06B6D4), const Color(0xFF3B82F6)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: sync.isSyncing
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'ĐANG NẠP (${(sync.progress * 100).toInt()}%)...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bolt, color: Colors.yellowAccent, size: 28),
                      SizedBox(width: 8),
                      Text(
                        '⚡ GỬI ĐỒNG BỘ CẢ 3 BẢNG',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // --- 8. BẢNG NHẬT KÝ CONSOLE LOG ---
  Widget _buildConsoleLogs(SyncController sync) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF050B14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blueGrey.shade900),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'NHẬT KÝ ĐIỀU KHIỂN (CONSOLE)',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                sync.currentStatus,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const Divider(color: Colors.blueGrey, height: 12),
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: sync.logs.length,
              itemBuilder: (context, idx) {
                final log = sync.logs[sync.logs.length - 1 - idx];
                Color logColor = Colors.grey.shade400;
                if (log.contains('THÀNH CÔNG')) logColor = Colors.greenAccent;
                if (log.contains('CẢNH BÁO') || log.contains('LỖI')) logColor = Colors.redAccent;
                if (log.contains('BẮT ĐẦU')) logColor = Colors.cyanAccent;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1.0),
                  child: Text(
                    log,
                    style: TextStyle(
                      color: logColor,
                      fontSize: 11,
                      fontFamily: 'monospace',
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
}

class _LedGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    const double cols = 64;
    const double rows = 32;
    final dx = size.width / cols;
    final dy = size.height / rows;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        canvas.drawCircle(Offset(c * dx + dx / 2, r * dy + dy / 2), 0.7, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
