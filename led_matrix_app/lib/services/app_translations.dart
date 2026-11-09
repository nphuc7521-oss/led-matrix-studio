class AppTranslations {
  static const String vi = 'vi';
  static const String th = 'th';

  static final Map<String, Map<String, String>> _strings = {
    // App Bar
    'app_title': {
      'vi': 'HD2020 LED STUDIO PRO',
      'th': 'HD2020 LED STUDIO PRO',
    },
    'status_ready': {
      'vi': '📡 Sẵn sàng điều khiển Dark Studio V18',
      'th': '📡 พร้อมควบคุม Dark Studio V18',
    },
    'tooltip_wifi_search': {
      'vi': 'Chọn nhanh Wi-Fi Card LED',
      'th': 'ค้นหาและเลือก Wi-Fi การ์ด LED',
    },
    'tooltip_settings': {
      'vi': 'Cài đặt SSID & Mật khẩu',
      'th': 'ตั้งค่า SSID & รหัสผ่าน',
    },

    // Tabs
    'board_empty': {
      'vi': '(Trống)',
      'th': '(ว่าง)',
    },

    // Simulator
    'sim_title': {
      'vi': 'MÔ PHỎNG',
      'th': 'จำลองการแสดงผล',
    },
    'sim_play': {
      'vi': 'Chạy',
      'th': 'เล่น',
    },
    'sim_pause': {
      'vi': 'Dừng',
      'th': 'หยุด',
    },
    'badge_effect': {
      'vi': 'Hiệu ứng: ',
      'th': 'เอฟเฟกต์: ',
    },
    'badge_border_on': {
      'vi': 'Viền: BẬT (Mẫu {num})',
      'th': 'กรอบ: เปิด (แบบ {num})',
    },
    'badge_border_off': {
      'vi': 'Viền: TẮT',
      'th': 'กรอบ: ปิด',
    },

    // Resolution
    'res_title': {
      'vi': 'Độ Phân Giải: ',
      'th': 'ความละเอียด: ',
    },
    'res_btn_custom': {
      'vi': 'Nhập số đo...',
      'th': 'ระบุขนาด...',
    },
    'res_custom_dropdown': {
      'vi': '⚙ Tùy chỉnh kích thước khác...',
      'th': '⚙ กำหนดขนาดอื่น...',
    },
    'res_custom_current': {
      'vi': '⚙ Tùy chỉnh: {w} × {h} px',
      'th': '⚙ กำหนดเอง: {w} × {h} px',
    },
    'res_dialog_title': {
      'vi': 'Tùy Chỉnh Kích Thước ({name})',
      'th': 'กำหนดขนาด ({name})',
    },
    'res_dialog_desc': {
      'vi': 'Nhập số điểm ảnh (pixel) ngang và dọc của bảng LED:',
      'th': 'ป้อนจำนวนพิกเซลแนวนอนและแนวตั้งของบอร์ด LED:',
    },
    'res_dialog_width': {
      'vi': 'Chiều Rộng (Width)',
      'th': 'ความกว้าง (Width)',
    },
    'res_dialog_height': {
      'vi': 'Chiều Cao (Height)',
      'th': 'ความสูง (Height)',
    },
    'res_dialog_hint': {
      'vi': '💡 Lưu ý: Chiều rộng nên là bội số của 8 hoặc 16 (ví dụ: 64, 96, 128, 160, 192, 256...) để điểm ảnh thẳng hàng và sắc nét nhất.',
      'th': '💡 หมายเหตุ: ความกว้างควรเป็นพหุคูณของ 8 หรือ 16 (เช่น: 64, 96, 128, 160, 192, 256...) เพื่อให้เม็ดไฟเรียงตรงคมชัดที่สุด',
    },
    'res_dialog_cancel': {
      'vi': 'Hủy',
      'th': 'ยกเลิก',
    },
    'res_dialog_save_single': {
      'vi': 'Lưu Cho Bảng Này',
      'th': 'บันทึกบอร์ดนี้',
    },
    'res_dialog_save_all': {
      'vi': 'Áp dụng Cả 3 Bảng',
      'th': 'ใช้กับทั้ง 3 บอร์ด',
    },

    // Typography & Content
    'typo_title': {
      'vi': 'Nội Dung & Kiểu Chữ: ',
      'th': 'ข้อความ & รูปแบบอักษร: ',
    },
    'typo_rainbow_btn': {
      'vi': '[AB] 7 MÀU',
      'th': '[AB] 7 สี',
    },
    'typo_text_hint': {
      'vi': 'Nhập nội dung chữ hiển thị...',
      'th': 'พิมพ์ข้อความที่ต้องการแสดง...',
    },

    // Motion & Effects
    'motion_title': {
      'vi': 'Hiệu Ứng Di Chuyển & Tốc Độ',
      'th': 'เอฟเฟกต์การเคลื่อนไหว & ความเร็ว',
    },
    'motion_speed_label': {
      'vi': 'Tốc độ: {val} (1: Rất nhanh, 20: Chậm)',
      'th': 'ความเร็ว: {val} (1: เร็วมาก, 20: ช้า)',
    },
    'motion_stay_label': {
      'vi': 'Dừng: {val} giây',
      'th': 'หยุดค้าง: {val} วินาที',
    },

    // Run Border
    'border_title': {
      'vi': 'Viền Chạy Độc Lập (Hardware Run Border)',
      'th': 'กรอบไฟวิ่งอิสระ (Hardware Run Border)',
    },
    'border_speed': {
      'vi': 'Tốc độ viền:',
      'th': 'ความเร็วกรอบ:',
    },
    'border_speed_fast': {
      'vi': 'Nhanh',
      'th': 'เร็ว',
    },
    'border_speed_std': {
      'vi': 'Chuẩn',
      'th': 'มาตรฐาน',
    },
    'border_speed_slow': {
      'vi': 'Chậm',
      'th': 'ช้า',
    },
    'border_dir': {
      'vi': 'Chiều viền:',
      'th': 'ทิศทางกรอบ:',
    },
    'border_dir_cw': {
      'vi': 'Thuận chiều kim đồng hồ (Clockwise)',
      'th': 'ตามเข็มนาฬิกา (Clockwise)',
    },
    'border_dir_ccw': {
      'vi': 'Ngược chiều kim đồng hồ (Anti-clockwise)',
      'th': 'ทวนเข็มนาฬิกา (Anti-clockwise)',
    },

    // Console Logs
    'logs_title': {
      'vi': 'Nhật Ký Điều Khiển',
      'th': 'บันทึกการทำงาน (Log)',
    },
    'logs_clear': {
      'vi': 'Xóa nhật ký',
      'th': 'ล้างบันทึก',
    },

    // Bottom Sticky Bar
    'btn_sync_all': {
      'vi': '⚡ GỬI ĐỒNG BỘ CẢ 3 BẢNG (AUTO SYNC)',
      'th': '⚡ ส่งพร้อมกันทั้ง 3 บอร์ด (AUTO SYNC)',
    },
    'btn_sync_single': {
      'vi': '📡 NẠP RIÊNG {name} ({ssid})',
      'th': '📡 ส่งเฉพาะ {name} ({ssid})',
    },
    'btn_syncing': {
      'vi': 'ĐANG NẠP DỮ LIỆU...',
      'th': 'กำลังส่งข้อมูล...',
    },

    // Settings Screen
    'settings_title': {
      'vi': 'CÀI ĐẶT 3 BẢNG LED',
      'th': 'ตั้งค่าบอร์ด LED ทั้ง 3',
    },
    'settings_ssid': {
      'vi': 'Tên WiFi (SSID)',
      'th': 'ชื่อ WiFi (SSID)',
    },
    'settings_pwd': {
      'vi': 'Mật khẩu WiFi',
      'th': 'รหัสผ่าน WiFi',
    },
    'settings_save': {
      'vi': 'Lưu bảng này',
      'th': 'บันทึกบอร์ดนี้',
    },
    'settings_updated': {
      'vi': 'Đã cập nhật {name}!',
      'th': 'อัปเดต {name} เรียบร้อย!',
    },
    'settings_language': {
      'vi': 'Ngôn ngữ (Language)',
      'th': 'ภาษา (Language)',
    },
  };

  static String tr(String key, String lang, [Map<String, String>? params]) {
    final entry = _strings[key];
    String text = entry?[lang] ?? entry?['vi'] ?? key;
    if (params != null) {
      params.forEach((paramKey, paramVal) {
        text = text.replaceAll('{$paramKey}', paramVal);
      });
    }
    return text;
  }
}
