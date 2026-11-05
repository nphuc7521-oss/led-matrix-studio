#ifndef WEB_UI_H
#define WEB_UI_H

#include <Arduino.h>

const char INDEX_HTML[] PROGMEM = R"rawliteral(<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0,maximum-scale=1.0,user-scalable=no">
<title>ESP32-S3 LED Studio Pro</title>
<style>
:root{--bg:#0b0f19;--card:#182234;--border:#243248;--cyan:#06b6d4;--green:#10b981;--red:#ef4444;--text:#f8fafc;--muted:#94a3b8}
*{box-sizing:border-box;margin:0;padding:0;font-family:-apple-system,BlinkMacSystemFont,Segoe UI,Roboto,sans-serif;-webkit-tap-highlight-color:transparent}
body{background:var(--bg);color:var(--text);padding:12px;padding-bottom:80px;min-height:100vh}
header{display:flex;align-items:center;justify-content:space-between;padding-bottom:12px;border-bottom:1px solid var(--border);margin-bottom:14px}
.brand{font-size:16px;font-weight:900;color:var(--cyan);letter-spacing:0.5px}
.status{display:flex;align-items:center;gap:6px;font-size:11px;background:rgba(16,185,129,0.15);color:var(--green);padding:4px 10px;border-radius:20px;border:1px solid var(--green)}
.dot{width:7px;height:7px;border-radius:50%;background:var(--green);animation:blink 1.2s infinite}
@keyframes blink{0%,100%{opacity:1}50%{opacity:0.3}}
.tabs{display:flex;gap:6px;margin-bottom:14px}
.tab-btn{flex:1;padding:10px 4px;background:var(--card);border:1px solid var(--border);border-radius:8px;color:var(--muted);font-weight:700;font-size:13px;cursor:pointer;text-align:center}
.tab-btn.active{background:var(--cyan);color:#000;border-color:var(--cyan);box-shadow:0 0 12px rgba(6,182,212,0.4)}
.card{background:var(--card);border:1px solid var(--border);border-radius:12px;padding:14px;margin-bottom:14px}
.card-title{font-size:12px;font-weight:800;color:var(--muted);text-transform:uppercase;margin-bottom:10px;display:flex;justify-content:space-between}
.input-group{margin-bottom:12px}
label{display:block;font-size:11px;font-weight:700;color:var(--muted);margin-bottom:5px}
input[type="text"],select{width:100%;padding:10px;background:#050811;border:1px solid var(--border);border-radius:8px;color:#fff;font-size:16px}
input[type="text"]:focus,select:focus{border-color:var(--cyan);outline:none}
.color-row{display:flex;gap:8px;margin-top:6px}
.color-btn{flex:1;height:34px;border-radius:6px;border:2px solid transparent;cursor:pointer;font-size:11px;font-weight:800;display:flex;align-items:center;justify-content:center}
.color-btn.active{border-color:#fff;box-shadow:0 0 10px currentColor}
.row-2{display:grid;grid-template-columns:1fr 1fr;gap:10px}
.fixed-btn{position:fixed;bottom:14px;left:14px;right:14px;z-index:99}
.btn-send{width:100%;padding:14px;background:linear-gradient(135deg,#059669,#10b981);border:none;border-radius:10px;color:#fff;font-size:16px;font-weight:900;cursor:pointer;box-shadow:0 4px 20px rgba(16,185,129,0.5)}
.btn-send:disabled{opacity:0.5}
.log-box{background:#050811;border:1px solid var(--border);border-radius:8px;padding:10px;font-family:monospace;font-size:11px;color:#34d399;max-height:120px;overflow-y:auto;white-space:pre-wrap;margin-top:10px}
</style>
</head>
<body>
<header>
  <div class="brand">⚡ ESP32-S3 LED BRIDGE</div>
  <div class="status"><span class="dot"></span> Online</div>
</header>

<div class="tabs">
  <button class="tab-btn active" onclick="switchBoard(0)">BẢNG 1</button>
  <button class="tab-btn" onclick="switchBoard(1)">BẢNG 2</button>
  <button class="tab-btn" onclick="switchBoard(2)">BẢNG 3</button>
</div>

<div class="card">
  <div class="card-title">
    <span id="boardHeader">CẤU HÌNH BẢNG 1 (WF2_f412fab2b75c)</span>
    <span style="color:var(--cyan)">64 × 32 px</span>
  </div>
  <div class="input-group">
    <label>NỘI DUNG CHỮ HIỂN THỊ:</label>
    <input type="text" id="boardText" placeholder="Nhập chữ..." oninput="updateCurBoard()">
  </div>
  <div class="input-group">
    <label>MÀU SẮC CHỮ:</label>
    <div class="color-row">
      <button class="color-btn active" style="background:#ef4444;color:#fff" onclick="setColor('red',this)">ĐỎ</button>
      <button class="color-btn" style="background:#10b981;color:#fff" onclick="setColor('green',this)">XANH</button>
      <button class="color-btn" style="background:#3b82f6;color:#fff" onclick="setColor('blue',this)">DƯƠNG</button>
      <button class="color-btn" style="background:#eab308;color:#000" onclick="setColor('yellow',this)">VÀNG</button>
      <button class="color-btn" style="background:linear-gradient(90deg,#ef4444,#10b981,#3b82f6);color:#fff" onclick="setColor('rainbow',this)">7 MÀU</button>
    </div>
  </div>
  <div class="row-2">
    <div class="input-group">
      <label>HIỆU ỨNG:</label>
      <select id="boardEffect" onchange="updateCurBoard()">
        <option value="1">Chạy chữ sang trái</option>
        <option value="2">Chạy chữ sang phải</option>
        <option value="37">Cuộn lên trên</option>
        <option value="36">Cuộn xuống dưới</option>
        <option value="39">Kéo giãn ngang</option>
        <option value="0">Hiển thị cố định (Đứng yên)</option>
      </select>
    </div>
    <div class="input-group">
      <label>VIỀN CHẠY:</label>
      <select id="boardBorder" onchange="updateCurBoard()">
        <option value="1">BẬT Viền Chạy</option>
        <option value="0">TẮT Viền</option>
      </select>
    </div>
  </div>
</div>

<div class="card">
  <div class="card-title">TIẾN TRÌNH ĐỒNG BỘ 3 BẢNG</div>
  <div class="log-box" id="logBox">[SẴN SÀNG] Kết nối trực tiếp từ iPhone/Android! Nhấn GỬI ĐỒNG BỘ để bắt đầu.</div>
</div>

<div class="fixed-btn">
  <button class="btn-send" id="btnSend" onclick="sendSyncAll()">⚡ GỬI ĐỒNG BỘ CẢ 3 BẢNG</button>
</div>

<script>
let curIdx = 0;
const boards = [
  { text: "PHÚC", color: "red", effect: 1, border: 1, ssid: "WF2_f412fab2b75c" },
  { text: "NGUYỄN", color: "green", effect: 2, border: 1, ssid: "WF2_1051db45b870" },
  { text: "HOÀNG", color: "yellow", effect: 37, border: 1, ssid: "WF2_f412fab177c8" }
];

function switchBoard(idx) {
  curIdx = idx;
  document.querySelectorAll('.tab-btn').forEach((b, i) => b.classList.toggle('active', i === idx));
  const b = boards[idx];
  document.getElementById('boardHeader').textContent = `CẤU HÌNH BẢNG ${idx + 1} (${b.ssid})`;
  document.getElementById('boardText').value = b.text;
  document.getElementById('boardEffect').value = b.effect;
  document.getElementById('boardBorder').value = b.border;
  document.querySelectorAll('.color-btn').forEach(btn => {
    btn.classList.toggle('active', btn.textContent.toLowerCase().includes(b.color) || (b.color==='rainbow' && btn.textContent.includes('7')));
  });
}

function setColor(c, btn) {
  boards[curIdx].color = c;
  document.querySelectorAll('.color-btn').forEach(b => b.classList.remove('active'));
  btn.classList.add('active');
}

function updateCurBoard() {
  boards[curIdx].text = document.getElementById('boardText').value;
  boards[curIdx].effect = parseInt(document.getElementById('boardEffect').value);
  boards[curIdx].border = parseInt(document.getElementById('boardBorder').value);
}

function log(msg) {
  const box = document.getElementById('logBox');
  box.textContent += "\n" + msg;
  box.scrollTop = box.scrollHeight;
}

function sendSyncAll() {
  updateCurBoard();
  const btn = document.getElementById('btnSend');
  btn.disabled = true;
  btn.textContent = "⏳ ĐANG GỬI ĐỒNG BỘ 3 BẢNG...";
  log(">>> Bắt đầu gửi dữ liệu sang ESP32-S3...");

  fetch('/api/send', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ boards: boards })
  }).then(r => r.json()).then(data => {
    log("[ESP32-S3] Nhận lệnh thành công! Đang tự động nhảy qua 3 bảng...");
    pollStatus();
  }).catch(e => {
    log("[LỖI] " + e);
    btn.disabled = false;
    btn.textContent = "⚡ GỬI ĐỒNG BỘ CẢ 3 BẢNG";
  });
}

function pollStatus() {
  const btn = document.getElementById('btnSend');
  const timer = setInterval(() => {
    fetch('/api/status').then(r => r.json()).then(res => {
      if (res.log) log(res.log);
      if (res.done) {
        clearInterval(timer);
        btn.disabled = false;
        btn.textContent = "⚡ GỬI ĐỒNG BỘ CẢ 3 BẢNG";
        log("=== [HOÀN TẤT ĐỒNG BỘ CẢ 3 BẢNG THÀNH CÔNG] ===");
      }
    }).catch(()=>{});
  }, 1000);
}

switchBoard(0);
</script>
</body>
</html>
)rawliteral";

#endif
