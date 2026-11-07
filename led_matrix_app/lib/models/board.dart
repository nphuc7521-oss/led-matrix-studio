class LedBoard {
  final String id;
  String name;
  String ssid;
  String password;
  String ip;
  int port;
  String? guid;

  // Thuộc tính hiển thị & văn bản chuẩn Studio V18
  String text;
  String color; // 'green', 'red', 'yellow', 'blue', 'cyan', 'magenta', 'white'
  String fontFamily; // 'Arial', 'Tahoma', 'Segoe UI', 'Consolas', 'Times New Roman'
  int fontSize; // 10, 12, 14, 16, 18, 20
  bool bold;
  bool italic;
  bool underline;
  String alignH; // 'left', 'center', 'right'
  String alignV; // 'top', 'center', 'bottom'
  int effect; // 1: Trái, 2: Phải, 37: Lên, 36: Xuống, 38: Dọc, 39: Ngang, 11: Mở giữa, 28: Tuyết, 34: Nhấp nháy, 202: Liên tục, 0: Tĩnh
  int speed; // 1..20
  int stayTime; // 1..10 (giây)
  int colorfulWords; // 0: Đơn sắc, 1..8: 7 Màu Gradient [AB]
  int borderStyle; // 0: Tắt viền, 1..7: Mẫu viền chạy 001..007
  int borderSpeed; // 2: Nhanh, 5: Chuẩn, 8: Chậm
  String borderMode; // 'Clockwise' hoặc 'Anti-clockwise'

  LedBoard({
    required this.id,
    required this.name,
    required this.ssid,
    this.password = '88888888',
    this.ip = '192.168.4.1',
    this.port = 6101,
    this.guid,
    this.text = '',
    this.color = 'green',
    this.fontFamily = 'Arial',
    this.fontSize = 16,
    this.bold = true,
    this.italic = false,
    this.underline = false,
    this.alignH = 'center',
    this.alignV = 'center',
    this.effect = 1,
    this.speed = 10,
    this.stayTime = 3,
    this.colorfulWords = 1, // Mặc định 7 màu [AB] rực rỡ như Web V18
    this.borderStyle = 1, // Mặc định bật Viền mẫu 001
    this.borderSpeed = 5,
    this.borderMode = 'Clockwise',
  });

  static List<LedBoard> defaultBoards() => [
        LedBoard(
          id: '1',
          name: 'BẢNG 1',
          ssid: 'WF2_f412fab2b75c',
          guid: '7100ff00-b2fa-0d00-2000-014e4300001a',
          text: 'HOÀNG',
          color: 'cyan',
          colorfulWords: 1,
          effect: 1, // Chạy chữ sang trái (Move Left)
          speed: 10,
          stayTime: 1,
          borderStyle: 1,
          bold: true,
        ),
        LedBoard(
          id: '2',
          name: 'BẢNG 2',
          ssid: 'WF2_1051db45b870',
          guid: '7100ff00-b870-0d00-2000-014e4300001b',
          text: 'NGUYỄN',
          color: 'yellow',
          colorfulWords: 1,
          effect: 1, // Chạy chữ sang trái (Move Left)
          speed: 10,
          stayTime: 1,
          borderStyle: 1,
          bold: true,
        ),
        LedBoard(
          id: '3',
          name: 'BẢNG 3',
          ssid: 'WF2_f412fab177c8',
          guid: '7100ff00-77c8-0d00-2000-014e4300001c',
          text: 'PHÚC',
          color: 'green',
          colorfulWords: 1,
          effect: 1, // Chạy chữ sang trái (Move Left)
          speed: 10,
          stayTime: 1,
          borderStyle: 1,
          bold: true,
        ),
      ];
}
