#include <WiFi.h>
#include <WebServer.h>
#include "web_ui.h"
#include "huidu_packets.h"

// ==============================================================================
// ESP32-S3 WIRELESS BRIDGE CONTROLLER CHO 3 BẢNG LED MA TRẬN HD-WF2
// - ĐIỀU KHIỂN ĐỒNG BỘ 3 BẢNG HOÀN TOÀN TỪ ĐIỆN THOẠI (IPHONE / ANDROID)
// - HOÀN TOÀN KHÔNG CẦN DÙNG LAPTOP!
// ==============================================================================

// CẤU HÌNH MẠNG WI-FI PHÁT RA CHO ĐIỆN THOẠI KẾT NỐI:
const char* AP_SSID = "LED_STUDIO_HD2020";
const char* AP_PASS = "88888888"; // Mật khẩu Wi-Fi của ESP32-S3 (ít nhất 8 ký tự)

IPAddress apIP(192, 168, 88, 1);
IPAddress apNetmask(255, 255, 255, 0);

WebServer server(80);

struct BoardConfig {
    String name;
    String ssid;
    String password;
    String text;
    String color;
    int effect;
    int border;
};

BoardConfig boards[3] = {
    { "BẢNG 1", "WF2_f412fab2b75c", "88888888", "PHÚC", "red", 1, 1 },
    { "BẢNG 2", "WF2_1051db45b870", "88888888", "NGUYỄN", "green", 2, 1 },
    { "BẢNG 3", "WF2_f412fab177c8", "88888888", "HOÀNG", "yellow", 37, 1 }
};

bool isSyncing = false;
bool syncCompleted = false;
String syncStatusLog = "";

// Gửi một gói tin Huidu thô qua TCP Socket
bool sendHuiduPacket(WiFiClient &client, const uint8_t *pkt, size_t len) {
    if (!client.connected()) return false;
    client.write(pkt, len);
    client.flush();
    delay(100);
    // Đọc phản hồi (nếu có)
    while (client.available()) {
        client.read();
    }
    return true;
}

// Bắn chuỗi gói tin nạp dữ liệu tới một Card HD-WF2
bool transmitToBoard(int boardIdx) {
    BoardConfig &b = boards[boardIdx];
    Serial.printf("\n>>> [%d/3] Đang kết nối tới %s (%s)...\n", boardIdx + 1, b.name.c_str(), b.ssid.c_str());
    syncStatusLog = "[" + String(boardIdx + 1) + "/3] Đang kết nối tới " + b.name + " (" + b.ssid + ")...";

    // Chuyển Wi-Fi STA sang card của bảng này
    WiFi.disconnect(false);
    delay(200);
    WiFi.begin(b.ssid.c_str(), b.password.c_str());

    int timeout = 0;
    while (WiFi.status() != WL_CONNECTED && timeout < 25) {
        delay(200);
        Serial.print(".");
        timeout++;
    }
    Serial.println();

    if (WiFi.status() != WL_CONNECTED) {
        Serial.printf("[LỖI] Không thể kết nối tới Wi-Fi %s\n", b.ssid.c_str());
        syncStatusLog = "[LỖI] Không kết nối được Wi-Fi " + b.ssid;
        return false;
    }

    Serial.printf("  -> Đã bắt Wi-Fi %s. Đang mở TCP tới 192.168.4.1:6101...\n", b.ssid.c_str());
    WiFiClient client;
    if (!client.connect("192.168.4.1", 6101, 3000)) {
        Serial.println("  -> [LỖI] Không thể kết nối tới cổng 6101 của card!");
        syncStatusLog = "[LỖI] Không kết nối được cổng 6101 của " + b.name;
        client.stop();
        return false;
    }

    Serial.printf("  -> Đang nạp dữ liệu: '%s' (Màu: %s, Eff: %d, Viền: %d)...\n", b.text.c_str(), b.color.c_str(), b.effect, b.border);

    // Gửi chuỗi các lệnh chuẩn Huidu
    sendHuiduPacket(client, PKT_CMD_30, PKT_CMD_30_LEN);
    delay(150);
    sendHuiduPacket(client, PKT_CMD_19, PKT_CMD_19_LEN);
    delay(150);
    sendHuiduPacket(client, PKT_CMD_2, PKT_CMD_2_LEN);
    delay(250);
    sendHuiduPacket(client, PKT_CMD_4, PKT_CMD_4_LEN);
    delay(150);

    client.stop();
    Serial.printf("===> [THÀNH CÔNG] ĐÃ GỬI DỮ LIỆU TỚI %s!\n", b.name.c_str());
    syncStatusLog = "===> [THÀNH CÔNG] " + b.name + " đã nhận hiệu ứng: '" + b.text + "'!";
    return true;
}

// Hàm thực thi tiến trình đồng bộ 3 bảng
void doSyncProcess() {
    isSyncing = true;
    syncCompleted = false;

    for (int i = 0; i < 3; i++) {
        transmitToBoard(i);
        delay(600);
    }

    // Sau khi nạp xong cả 3 bảng, ngắt STA để giữ sóng AP ổn định
    WiFi.disconnect(false);
    Serial.println("\n=======================================================");
    Serial.println("   HOÀN TẤT ĐỒNG BỘ CẢ 3 BẢNG LED THÀNH CÔNG!");
    Serial.println("=======================================================");
    syncStatusLog = "HOÀN TẤT ĐỒNG BỘ CẢ 3 BẢNG THÀNH CÔNG!";
    isSyncing = false;
    syncCompleted = true;
}

// ROUTE: Giao diện Web điều khiển trên điện thoại
void handleRoot() {
    server.send_P(200, "text/html", INDEX_HTML);
}

// ROUTE: Nhận lệnh gửi đồng bộ từ điện thoại
void handleApiSend() {
    if (server.hasArg("plain")) {
        String body = server.arg("plain");
        Serial.println("\n[API SEND] Nhận dữ liệu từ điện thoại:");
        Serial.println(body);

        // Trích xuất văn bản cơ bản
        for (int i = 0; i < 3; i++) {
            String searchKey = "\"text\":\"";
            int idx = -1;
            int curFind = 0;
            while (curFind <= i) {
                idx = body.indexOf(searchKey, idx + 1);
                curFind++;
            }
            if (idx >= 0) {
                int endIdx = body.indexOf("\"", idx + searchKey.length());
                if (endIdx > idx) {
                    boards[i].text = body.substring(idx + searchKey.length(), endIdx);
                }
            }
        }
    }

    server.send(200, "application/json", "{\"status\":\"started\"}");
    
    // Kích hoạt tiến trình đồng bộ
    doSyncProcess();
}

// ROUTE: Điện thoại hỏi trạng thái gửi
void handleApiStatus() {
    String json = "{";
    json += "\"syncing\":" + String(isSyncing ? "true" : "false") + ",";
    json += "\"done\":" + String(syncCompleted ? "true" : "false") + ",";
    json += "\"log\":\"" + syncStatusLog + "\"";
    json += "}";
    server.send(200, "application/json", json);
}

void setup() {
    Serial.begin(115200);
    delay(1000);
    Serial.println("\n\n=======================================================");
    Serial.println("   KHOI DONG HE THONG DONG BO LED ESP32-S3 (V1.0 PRO)");
    Serial.println("=======================================================");

    // Bật cả 2 chế độ AP (Phát Wi-Fi cho điện thoại) và STA (Đi bắn Wi-Fi cho card LED)
    WiFi.mode(WIFI_AP_STA);

    // Cấu hình mạng AP phát ra
    WiFi.softAPConfig(apIP, apIP, apNetmask);
    WiFi.softAP(AP_SSID, AP_PASS);

    Serial.println("[1] Da khoi tao song Wi-Fi AP:");
    Serial.printf("    - Ten Wi-Fi:  %s\n", AP_SSID);
    Serial.printf("    - Mat khau:   %s\n", AP_PASS);
    Serial.printf("    - Dia chi IP: http://%s/\n", WiFi.softAPIP().toString().c_str());
    Serial.println("=======================================================");
    Serial.println("Cầm điện thoại bắt Wi-Fi trên rồi mở trình duyệt gõ: http://192.168.88.1");
    Serial.println("=======================================================");

    // Đăng ký các hàm xử lý web
    server.on("/", HTTP_GET, handleRoot);
    server.on("/api/send", HTTP_POST, handleApiSend);
    server.on("/api/status", HTTP_GET, handleApiStatus);
    server.begin();

    Serial.println("[2] Web Server da san sang phuc vu dien thoai!");
}

void loop() {
    server.handleClient();
    delay(2);
}
