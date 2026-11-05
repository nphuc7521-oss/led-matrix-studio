class LedBoard {
  final String id;
  String name;
  String ssid;
  String password;
  String ip;
  int port;
  String? guid;

  // Thuộc tính nội dung & hiển thị riêng của từng bảng
  String text;
  String color; // 'red', 'green', 'blue', 'yellow', 'cyan', 'magenta', 'white'
  int fontSize;
  int effect; // 1: Chạy trái, 2: Chạy phải, 37: Cuộn lên, 36: Cuộn xuống, 39: Kéo giãn, 0: Đứng yên
  int speed;
  int stayTime;
  int colorfulWords; // 0: Đơn sắc, 1: 7 Màu Gradient [AB]
  int borderStyle;   // 0: Tắt viền, 1..7: Mẫu viền chạy 001..007
  int borderSpeed;
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
    this.color = 'red',
    this.fontSize = 16,
    this.effect = 1,
    this.speed = 10,
    this.stayTime = 3,
    this.colorfulWords = 0,
    this.borderStyle = 1,
    this.borderSpeed = 5,
    this.borderMode = 'Clockwise',
  });

  static List<LedBoard> defaultBoards() => [
        LedBoard(
          id: '1',
          name: 'BẢNG 1',
          ssid: 'WF2_f412fab2b75c',
          guid: '7100ff00-b2fa-0d00-2000-014e4300001a',
          text: 'PHÚC',
          color: 'red',
          colorfulWords: 1, // 7 Màu [AB]
          effect: 1, // Chạy trái
          borderStyle: 1,
        ),
        LedBoard(
          id: '2',
          name: 'BẢNG 2',
          ssid: 'WF2_1051db45b870',
          guid: '7100ff00-b870-0d00-2000-014e4300001b',
          text: 'NGUYỄN',
          color: 'green',
          colorfulWords: 1,
          effect: 2, // Chạy phải
          borderStyle: 1,
        ),
        LedBoard(
          id: '3',
          name: 'BẢNG 3',
          ssid: 'WF2_f412fab177c8',
          guid: '7100ff00-77c8-0d00-2000-014e4300001c',
          text: 'HOÀNG',
          color: 'yellow',
          colorfulWords: 1,
          effect: 37, // Cuộn lên
          borderStyle: 1,
        ),
      ];
}
