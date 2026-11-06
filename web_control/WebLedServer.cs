using System;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Threading;
using System.Runtime.InteropServices;
using System.Diagnostics;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.Drawing.Drawing2D;
using System.Drawing.Text;

namespace LedMatrixWeb {
    class Program {
        [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        public static extern bool SetDllDirectory(string lpPathName);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern IntPtr LoadLibrary(string lpFileName);

        [DllImport("HDSDK.dll", CallingConvention = CallingConvention.StdCall)]
        public static extern int Hd_CreateScreen(int nWidth, int nHeight, int nColor, int nGray, int nCardType, IntPtr pParams, int nReserved);

        [DllImport("HDSDK.dll", CallingConvention = CallingConvention.StdCall)]
        public static extern int Hd_AddProgram([MarshalAs(UnmanagedType.LPWStr)] string pBorderImgPath, int nBorderEffect, int nBorderSpeed, IntPtr pExParamsBuf, int nBufSize);

        [DllImport("HDSDK.dll", CallingConvention = CallingConvention.StdCall)]
        public static extern int Hd_AddArea(int nProgramID, int nX, int nY, int nWidth, int nHeight, [MarshalAs(UnmanagedType.LPWStr)] string pBorderImgPath, int nBorderEffect, int nBorderSpeed, IntPtr pExParamsBuf, int nBufSize);

        [DllImport("HDSDK.dll", CallingConvention = CallingConvention.StdCall)]
        public static extern int Hd_AddSimpleTextAreaItem(int nAreaID, [MarshalAs(UnmanagedType.LPWStr)] string pText, int nTextColor, int nBackGroupColor, int nStyle, [MarshalAs(UnmanagedType.LPWStr)] string pFontName, int nFontHeight, int nShowEffect, int nShowSpeed, int nClearType, int nStayTime, IntPtr pExParamsBuf, int nBufSize);

        [DllImport("HDSDK.dll", CallingConvention = CallingConvention.StdCall)]
        public static extern int Hd_AddImageAreaItem(int nAreaID, [MarshalAs(UnmanagedType.LPWStr)] string pFilePath, int nShowEffect, int nShowSpeed, int nClearType, int nStayTime, IntPtr pExParamsBuf, int nBufSize);

        [DllImport("HDSDK.dll", CallingConvention = CallingConvention.StdCall)]
        public static extern int Hd_GetColor(int r, int g, int b);

        [DllImport("HDSDK.dll", EntryPoint = "Hd_SendScreen", CallingConvention = CallingConvention.StdCall)]
        public static extern int Hd_SendScreenW(int nSendType, [MarshalAs(UnmanagedType.LPWStr)] string pStrParams, [MarshalAs(UnmanagedType.LPWStr)] string pDeviceGUID, IntPtr pExParamsBuf, int nBufSize);

        [DllImport("HDSDK.dll", EntryPoint = "Hd_SendScreen", CallingConvention = CallingConvention.StdCall)]
        public static extern int Hd_SendScreenA(int nSendType, [MarshalAs(UnmanagedType.LPStr)] string pStrParams, [MarshalAs(UnmanagedType.LPStr)] string pDeviceGUID, IntPtr pExParamsBuf, int nBufSize);

        [DllImport("HDSDK.dll", EntryPoint = "Hd_SendScreenFromFile", CallingConvention = CallingConvention.StdCall, CharSet = CharSet.Unicode)]
        public static extern int Hd_SendScreenFromFile(int nSendType, string pStrParams, string pScreenFilePath, string pProgramFilePath, IntPtr pDeviceGUID);

        [DllImport("HDSDK.dll", EntryPoint = "Hd_SaveScreen", CallingConvention = CallingConvention.StdCall, CharSet = CharSet.Unicode)]
        public static extern int Hd_SaveScreen(string pDirPath);

        [DllImport("HDSDK.dll", CallingConvention = CallingConvention.StdCall)]
        public static extern int Hd_SendHardwardSetting(int nSendType, [MarshalAs(UnmanagedType.LPWStr)] string pStrParams, [MarshalAs(UnmanagedType.LPWStr)] string pSettingPath, [MarshalAs(UnmanagedType.LPWStr)] string pDeviceGUID, IntPtr pExParamsBuf, int nBufSize);

        [DllImport("HDSDK.dll", CallingConvention = CallingConvention.StdCall)]
        public static extern int Hd_GetSDKLastError();

        private static bool sdkLoaded = false;
        private static string appDir = "";
        private static string xhdsPath = @"C:\Users\PC\AppData\Roaming\Huidu\HD2020\customhardwaresetting\phuc.xhds";
        private static string hdInstallDir = @"C:\Program Files (x86)\HD2020";

        public class BoardItem {
            public int Id = 1;
            public string Name = "BẢNG 1";
            public string Ssid = "";
            public string Text = "";
            public string Color = "green";
            public int FontSize = 16;
            public string AlignH = "center";
            public string AlignV = "middle";
            public int Effect = 0;       // 0: Immediate, 1: Move Left, 202: Cont Move Left, 37: Pull Upward, 36: Pull Downward, 11: Open middle, 28: Snow, 34: Twinkle...
            public int Speed = 10;
            public int StayTime = 3;
            public bool Bold = true;
            public bool Italic = false;
            public bool Underline = false;
            // Nút [AB] - Chữ 7 màu / Colorful Words
            public int ColorfulWords = 0; // 0: None, 1..8: Presets
            // Nút [A] - Nét chữ & Viền
            public bool Hollow = false;
            public bool Stroke = false;
            public int StrokeWidth = 1;
            public string StrokeColor = "red";
            public bool Invert = false;
            // Viền chạy (Run Border)
            public int BorderStyle = 0;   // 0: None, 1..5: Presets
            public int BorderSpeed = 5;
            public string BorderMode = "Clockwise";
        }

        static void Main(string[] args) {
            Console.OutputEncoding = Encoding.UTF8;
            appDir = AppDomain.CurrentDomain.BaseDirectory;

            if (Directory.Exists(hdInstallDir)) {
                SetDllDirectory(hdInstallDir);
                IntPtr hDll = LoadLibrary(Path.Combine(hdInstallDir, "HDSDK.dll"));
                if (hDll != IntPtr.Zero) {
                    sdkLoaded = true;
                    Console.WriteLine("[INFO] HDSDK.dll da duoc tai thanh cong tu: " + hdInstallDir);
                } else {
                    Console.WriteLine("[WARN] Khong the nap HDSDK.dll. Ma loi: " + Marshal.GetLastWin32Error());
                }
            } else {
                Console.WriteLine("[WARN] Khong tim thay thu muc: " + hdInstallDir);
            }

            // Kiểm tra file cấu hình phần cứng xhds
            if (!File.Exists(xhdsPath)) {
                string altXhds = @"C:\Users\PC\AppData\Roaming\Huidu\HD2020\customhardwaresetting\phuchoang.xhds";
                if (File.Exists(altXhds)) xhdsPath = altXhds;
            }
            Console.WriteLine("[INFO] File phan cung xhds: " + xhdsPath + " (Ton tai: " + File.Exists(xhdsPath) + ")");

            // Tự động quét và nạp profile cho tất cả các card WF2 đã có
            EnsureWifiProfileForSsid("WF2_f412fab2b75c", "88888888");
            EnsureWifiProfileForSsid("WF2_1051db45b870", "88888888");
            EnsureWifiProfileForSsid("WF2_f412fab177c8", "88888888");

            int port = 8080;
            TcpListener listener = null;

            // Tự động đóng các phiên máy chủ CŨ (V16, V15...) còn chạy ngầm đang chiếm cổng 8080.
            // Nếu không đóng, trình duyệt vẫn nói chuyện với bản cũ -> chữ trắng / màn tối thui.
            try {
                int myPid = Process.GetCurrentProcess().Id;
                foreach (Process p in Process.GetProcesses()) {
                    try {
                        string pn = p.ProcessName;
                        if (p.Id != myPid && (pn.StartsWith("WebLedSync", StringComparison.OrdinalIgnoreCase) || pn.Equals("WebLedServer", StringComparison.OrdinalIgnoreCase))) {
                            Console.WriteLine("[INFO] Dong phien may chu cu: " + pn + " (PID " + p.Id + ")");
                            p.Kill();
                            p.WaitForExit(3000);
                        }
                    } catch {}
                }
            } catch {}

            for (int bindTry = 1; bindTry <= 5 && listener == null; bindTry++) {
                try {
                    // Mở cổng 8080 cho TẤT CẢ các thiết bị (iPhone, Android, Máy tính cùng mạng Wi-Fi)
                    TcpListener l = new TcpListener(IPAddress.Any, port);
                    l.Start();
                    listener = l;
                } catch (Exception ex) {
                    Console.WriteLine("[WARN] Cong " + port + " dang bi chiem (lan " + bindTry + "): " + ex.Message);
                    Thread.Sleep(1000);
                }
            }

            try {
                if (listener == null) throw new Exception("Cong 8080 van bi chiem boi chuong trinh khac. Hay dong tat ca cua so may chu cu roi chay lai.");
                string localIp = GetLocalLanIp();
                Console.WriteLine("=============================================================");
                Console.WriteLine("   HE THONG HD2020 STUDIO V18 PRO - HO TRO IPHONE / ANDROID / PC");
                Console.WriteLine("   - May tinh:   http://localhost:" + port);
                Console.WriteLine("   - Dien thoai (iPhone/Android): http://" + localIp + ":" + port);
                Console.WriteLine("   - Fix dut diem vien chay theo chu: Vien chay quanh 4 canh ngoai doc lap 100%");
                Console.WriteLine("   - Chu 7 mau [AB] & Mau don sac, font net cang giua dep tuyet doi");
                Console.WriteLine("=============================================================");
            } catch (Exception ex) {
                Console.WriteLine("[ERROR] Khong the khoi dong Web Server tren cong " + port + ": " + ex.Message);
                return;
            }

            while (true) {
                try {
                    TcpClient client = listener.AcceptTcpClient();
                    ThreadPool.QueueUserWorkItem(ProcessClient, client);
                } catch (Exception ex) {
                    Console.WriteLine("[ERROR] Loi accept client: " + ex.Message);
                    break;
                }
            }
        }

        private static int FindHeaderEnd(byte[] buf, int len) {
            for (int i = 0; i <= len - 4; i++) {
                if (buf[i] == 13 && buf[i + 1] == 10 && buf[i + 2] == 13 && buf[i + 3] == 10) {
                    return i;
                }
            }
            return -1;
        }

        private static void ProcessClient(object state) {
            TcpClient client = (TcpClient)state;
            client.SendTimeout = 60000;
            client.ReceiveTimeout = 60000;

            try {
                using (NetworkStream stream = client.GetStream())
                using (MemoryStream ms = new MemoryStream()) {
                    byte[] chunk = new byte[16384];
                    int headerEndIdx = -1;
                    int contentLength = 0;

                    // Bước 1: Đọc cho đến khi nhận đủ toàn bộ HTTP Header (\r\n\r\n)
                    while (headerEndIdx < 0) {
                        int n = stream.Read(chunk, 0, chunk.Length);
                        if (n <= 0) break;
                        ms.Write(chunk, 0, n);
                        byte[] cur = ms.GetBuffer();
                        headerEndIdx = FindHeaderEnd(cur, (int)ms.Length);
                        if (ms.Length > 262144) break;
                    }

                    if (headerEndIdx < 0) { client.Close(); return; }

                    byte[] allBytes = ms.ToArray();
                    string headerStr = Encoding.UTF8.GetString(allBytes, 0, headerEndIdx);
                    string[] lines = headerStr.Split(new string[] { "\r\n" }, StringSplitOptions.None);
                    if (lines.Length == 0) { client.Close(); return; }

                    string[] firstLine = lines[0].Split(' ');
                    if (firstLine.Length < 2) { client.Close(); return; }

                    string method = firstLine[0];
                    string rawUrl = firstLine[1];

                    foreach (string hLine in lines) {
                        if (hLine.StartsWith("Content-Length:", StringComparison.OrdinalIgnoreCase)) {
                            string clVal = hLine.Substring(15).Trim();
                            int.TryParse(clVal, out contentLength);
                        }
                    }

                    // Bước 2: Đọc tiếp cho đến khi nhận ĐỦ 100% số byte của JSON Body (Content-Length)
                    // Khắc phục triệt để lỗi Chrome chia Header và JSON Body thành 2 gói TCP khiến body bị rỗng!
                    int bodyStartOffset = headerEndIdx + 4;
                    while ((int)ms.Length - bodyStartOffset < contentLength) {
                        int n = stream.Read(chunk, 0, chunk.Length);
                        if (n <= 0) break;
                        ms.Write(chunk, 0, n);
                    }

                    allBytes = ms.ToArray();
                    string body = "";
                    int actualBodyBytes = allBytes.Length - bodyStartOffset;
                    if (actualBodyBytes > 0) {
                        body = Encoding.UTF8.GetString(allBytes, bodyStartOffset, actualBodyBytes);
                    }

                    if (method == "OPTIONS") {
                        SendHttpResponse(stream, 204, "No Content", "text/plain", new byte[0]);
                        return;
                    }

                    if (rawUrl.StartsWith("/api/status") && method == "GET") {
                        HandleApiStatus(stream);
                    } else if (rawUrl.StartsWith("/api/send_status") && method == "GET") {
                        HandleApiSendStatus(stream);
                    } else if (rawUrl.StartsWith("/api/scan") && (method == "GET" || method == "POST")) {
                        HandleApiScan(stream);
                    } else if (rawUrl.StartsWith("/api/add_profile") && method == "POST") {
                        HandleApiAddProfile(stream, body);
                    } else if (rawUrl.StartsWith("/api/hw_setting") && method == "POST") {
                        HandleApiHwSetting(stream, body);
                    } else if (rawUrl.StartsWith("/api/send") && method == "POST") {
                        HandleApiSend(stream, body);
                    } else {
                        ServeStaticFile(stream, rawUrl);
                    }
                }
            } catch {}
            finally {
                try { client.Close(); } catch {}
            }
        }

        private static void SendHttpResponse(NetworkStream stream, int statusCode, string statusMsg, string contentType, byte[] bodyBytes) {
            string header = "HTTP/1.1 " + statusCode + " " + statusMsg + "\r\n" +
                            "Content-Type: " + contentType + "\r\n" +
                            "Content-Length: " + bodyBytes.Length + "\r\n" +
                            "Access-Control-Allow-Origin: *\r\n" +
                            "Access-Control-Allow-Methods: GET, POST, OPTIONS\r\n" +
                            "Access-Control-Allow-Headers: Content-Type\r\n" +
                            "Connection: close\r\n\r\n";
            byte[] headerBytes = Encoding.UTF8.GetBytes(header);
            stream.Write(headerBytes, 0, headerBytes.Length);
            if (bodyBytes.Length > 0) {
                stream.Write(bodyBytes, 0, bodyBytes.Length);
            }
            stream.Flush();
        }

        private static bool CheckTcpPort(string ip, int port, int timeoutMs) {
            try {
                using (TcpClient tcp = new TcpClient()) {
                    IAsyncResult ar = tcp.BeginConnect(ip, port, null, null);
                    bool success = ar.AsyncWaitHandle.WaitOne(timeoutMs);
                    if (success && tcp.Connected) {
                        tcp.EndConnect(ar);
                        return true;
                    }
                }
            } catch {}
            return false;
        }

        private static string GetCurrentWifiSsid() {
            try {
                ProcessStartInfo psi = new ProcessStartInfo("netsh", "wlan show interfaces");
                psi.CreateNoWindow = true;
                psi.UseShellExecute = false;
                psi.RedirectStandardOutput = true;
                Process p = Process.Start(psi);
                string output = p.StandardOutput.ReadToEnd();
                p.WaitForExit(1500);

                string[] lines = output.Split(new char[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries);
                foreach (string line in lines) {
                    string trimmed = line.Trim();
                    if (trimmed.StartsWith("SSID", StringComparison.OrdinalIgnoreCase) && !trimmed.StartsWith("BSSID", StringComparison.OrdinalIgnoreCase)) {
                        int colonIdx = trimmed.IndexOf(':');
                        if (colonIdx >= 0) {
                            string ssid = trimmed.Substring(colonIdx + 1).Trim();
                            if (!string.IsNullOrEmpty(ssid)) return ssid;
                        }
                    }
                }
            } catch {}
            return "";
        }

        private static string StringToHex(string str) {
            StringBuilder sb = new StringBuilder();
            foreach (char c in str) {
                sb.Append(((int)c).ToString("X2"));
            }
            return sb.ToString();
        }

        public static bool EnsureWifiProfileForSsid(string ssid, string password) {
            if (string.IsNullOrEmpty(ssid)) return false;
            if (string.IsNullOrEmpty(password)) password = "88888888";

            try {
                string hex = StringToHex(ssid);
                string xml = string.Format(@"<?xml version=""1.0""?>
<WLANProfile xmlns=""http://www.microsoft.com/networking/WLAN/profile/v1"">
	<name>{0}</name>
	<SSIDConfig>
		<SSID>
			<hex>{1}</hex>
			<name>{0}</name>
		</SSID>
	</SSIDConfig>
	<connectionType>ESS</connectionType>
	<connectionMode>manual</connectionMode>
	<MSM>
		<security>
			<authEncryption>
				<authentication>WPA2PSK</authentication>
				<encryption>AES</encryption>
				<useOneX>false</useOneX>
			</authEncryption>
			<sharedKey>
				<keyType>passPhrase</keyType>
				<protected>false</protected>
				<keyMaterial>{2}</keyMaterial>
			</sharedKey>
		</security>
	</MSM>
</WLANProfile>", ssid, hex, password);

                string tempFile = Path.Combine(Path.GetTempPath(), "wlan_" + ssid + ".xml");
                File.WriteAllText(tempFile, xml, Encoding.ASCII);

                ProcessStartInfo psi = new ProcessStartInfo("netsh", "wlan add profile filename=\"" + tempFile + "\" user=current");
                psi.CreateNoWindow = true;
                psi.UseShellExecute = false;
                Process p = Process.Start(psi);
                p.WaitForExit(3000);
                try { File.Delete(tempFile); } catch {}
                return true;
            } catch {
                return false;
            }
        }

        private static List<string> ScanWf2Networks() {
            HashSet<string> ssids = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

            try {
                ProcessStartInfo psi = new ProcessStartInfo("netsh", "wlan show networks mode=bssid");
                psi.CreateNoWindow = true;
                psi.UseShellExecute = false;
                psi.RedirectStandardOutput = true;
                Process p = Process.Start(psi);
                string output = p.StandardOutput.ReadToEnd();
                p.WaitForExit(3000);

                string[] lines = output.Split(new char[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries);
                foreach (string line in lines) {
                    string trimmed = line.Trim();
                    if (trimmed.StartsWith("SSID", StringComparison.OrdinalIgnoreCase) && !trimmed.StartsWith("BSSID", StringComparison.OrdinalIgnoreCase)) {
                        int colonIdx = trimmed.IndexOf(':');
                        if (colonIdx >= 0) {
                            string ssid = trimmed.Substring(colonIdx + 1).Trim();
                            if (ssid.StartsWith("WF2_", StringComparison.OrdinalIgnoreCase) || ssid.StartsWith("WF_", StringComparison.OrdinalIgnoreCase)) {
                                ssids.Add(ssid);
                            }
                        }
                    }
                }
            } catch {}

            try {
                ProcessStartInfo psi = new ProcessStartInfo("netsh", "wlan show profiles");
                psi.CreateNoWindow = true;
                psi.UseShellExecute = false;
                psi.RedirectStandardOutput = true;
                Process p = Process.Start(psi);
                string output = p.StandardOutput.ReadToEnd();
                p.WaitForExit(3000);

                string[] lines = output.Split(new char[] { '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries);
                foreach (string line in lines) {
                    string trimmed = line.Trim();
                    int colonIdx = trimmed.IndexOf(':');
                    if (colonIdx >= 0) {
                        string ssid = trimmed.Substring(colonIdx + 1).Trim();
                        if (ssid.StartsWith("WF2_", StringComparison.OrdinalIgnoreCase) || ssid.StartsWith("WF_", StringComparison.OrdinalIgnoreCase)) {
                            ssids.Add(ssid);
                        }
                    }
                }
            } catch {}

            ssids.Add("WF2_f412fab2b75c");
            ssids.Add("WF2_1051db45b870");
            ssids.Add("WF2_f412fab177c8");

            foreach (string ssid in ssids) {
                EnsureWifiProfileForSsid(ssid, "88888888");
            }

            return new List<string>(ssids);
        }

        private static void HandleApiScan(NetworkStream stream) {
            List<string> found = ScanWf2Networks();
            StringBuilder sb = new StringBuilder();
            sb.Append("{\"success\":true,\"count\":").Append(found.Count).Append(",\"cards\":[");
            for (int i = 0; i < found.Count; i++) {
                if (i > 0) sb.Append(",");
                sb.Append("\"").Append(EscapeJson(found[i])).Append("\"");
            }
            sb.Append("]}");

            byte[] b = Encoding.UTF8.GetBytes(sb.ToString());
            SendHttpResponse(stream, 200, "OK", "application/json; charset=utf-8", b);
        }

        private static void HandleApiAddProfile(NetworkStream stream, string body) {
            string ssid = GetJsonValue(body, "ssid");
            string pass = GetJsonValue(body, "password");
            if (string.IsNullOrEmpty(pass)) pass = "88888888";

            bool ok = false;
            if (!string.IsNullOrEmpty(ssid)) {
                ok = EnsureWifiProfileForSsid(ssid, pass);
            }

            string json = string.Format("{{\"success\":{0},\"ssid\":\"{1}\"}}", ok ? "true" : "false", EscapeJson(ssid));
            byte[] b = Encoding.UTF8.GetBytes(json);
            SendHttpResponse(stream, 200, "OK", "application/json; charset=utf-8", b);
        }

        private static string GetLocalLanIp() {
            try {
                foreach (IPAddress ip in Dns.GetHostAddresses(Dns.GetHostName())) {
                    if (ip.AddressFamily == AddressFamily.InterNetwork && !IPAddress.IsLoopback(ip)) {
                        string s = ip.ToString();
                        if (s.StartsWith("192.168.") || s.StartsWith("10.") || s.StartsWith("172.")) return s;
                    }
                }
            } catch {}
            return "192.168.0.105";
        }

        private static void HandleApiStatus(NetworkStream stream) {
            string boardIp = "192.168.4.1";
            bool isOnline = CheckTcpPort(boardIp, 6101, 600);
            string currentSsid = GetCurrentWifiSsid();
            string localIp = GetLocalLanIp();

            string json = string.Format("{{\"version\":\"V18\",\"online\":{0},\"ip\":\"{1}\",\"port\":6101,\"sdkLoaded\":{2},\"currentWifi\":\"{3}\",\"localIp\":\"{4}\"}}",
                isOnline ? "true" : "false", boardIp, sdkLoaded ? "true" : "false", EscapeJson(currentSsid), EscapeJson(localIp));

            byte[] b = Encoding.UTF8.GetBytes(json);
            SendHttpResponse(stream, 200, "OK", "application/json; charset=utf-8", b);
        }

        private static bool ConnectWifi(string ssid) {
            try {
                Console.WriteLine(">>> [WIFI] Chuyen sang ket noi: " + ssid);
                // Ngắt kết nối Wi-Fi hiện tại trước khi chuyển sang mới (tránh adapter bị kẹt)
                try {
                    ProcessStartInfo psiDis = new ProcessStartInfo("netsh", "wlan disconnect");
                    psiDis.CreateNoWindow = true;
                    psiDis.UseShellExecute = false;
                    Process pDis = Process.Start(psiDis);
                    pDis.WaitForExit(2000);
                    Thread.Sleep(1000); // Đợi adapter ngắt hoàn toàn
                } catch {}

                ProcessStartInfo psi = new ProcessStartInfo("netsh", "wlan connect name=\"" + ssid + "\"");
                psi.CreateNoWindow = true;
                psi.UseShellExecute = false;
                psi.RedirectStandardOutput = true;
                Process p = Process.Start(psi);
                string output = p.StandardOutput.ReadToEnd();
                p.WaitForExit(3000);
                Console.WriteLine("    [WIFI] netsh result: " + output.Trim());
                Thread.Sleep(1500); // Đợi adapter bắt sóng mới + nhận IP DHCP
                return true;
            } catch (Exception ex) {
                Console.WriteLine("[ERROR] ConnectWifi loi: " + ex.Message);
                return false;
            }
        }

        private static bool WaitForBoard(string ip, int port, int maxSeconds) {
            Console.WriteLine("    [WAIT] Cho ket noi toi " + ip + ":" + port + " (toi da " + maxSeconds + "s)...");
            for (int i = 0; i < maxSeconds * 2; i++) {
                Thread.Sleep(500);
                if (CheckTcpPort(ip, port, 500)) {
                    Console.WriteLine("    [WAIT] Da ket noi duoc sau " + ((i + 1) * 0.5) + "s");
                    Thread.Sleep(800);
                    return true;
                }
            }
            Console.WriteLine("    [WAIT] Het thoi gian cho " + maxSeconds + "s - THAT BAI");
            return false;
        }

        // =========================================================================
        // HÀM NẠP CẤU HÌNH PHẦN CỨNG CHO CARD MỚI TINH (KHẮC PHỤC TRIỆT ĐỂ VỠ CHỮ)
        // =========================================================================
        private static void HandleApiHwSetting(NetworkStream stream, string body) {
            string ssid = GetJsonValue(body, "ssid");
            if (string.IsNullOrEmpty(ssid)) ssid = "WF2_f412fab177c8";

            string detectedOriginalWifi = GetCurrentWifiSsid();
            string originalWifi = GetJsonValue(body, "originalWifi");
            if (string.IsNullOrEmpty(originalWifi)) originalWifi = detectedOriginalWifi;

            List<string> logs = new List<string>();
            logs.Add("============================================================");
            logs.Add(string.Format("BẮT ĐẦU NẠP CẤU HÌNH PHẦN CỨNG CHO CARD: {0}", ssid));

            if (!File.Exists(xhdsPath)) {
                SendJsonResult(stream, false, "Khong tim thay file cau hinh phan cung phuc.xhds tren may!", -1, new string[] { "Thiếu file phuc.xhds" });
                return;
            }

            EnsureWifiProfileForSsid(ssid, "88888888");
            ConnectWifi(ssid);

            bool success = false;
            if (WaitForBoard("192.168.4.1", 6101, 12)) {
                logs.Add(string.Format("Đã kết nối thành công tới card {0}. Đang nạp cấu hình quét HUB75 64x32...", ssid));
                int res = Hd_SendHardwardSetting(0, "192.168.4.1", xhdsPath, null, IntPtr.Zero, 0);
                if (res == 0) {
                    success = true;
                    logs.Add("  ===> [THÀNH CÔNG] ĐÃ NẠP CẤU HÌNH PHẦN CỨNG VĨNH VIỄN VÀO FLASH CỦA CARD!");
                    logs.Add("  ===> Card hiện tại đã nhận diện đúng màn hình P4/P5 HUB75 scan 1/16. Không bao giờ bị vỡ chữ nữa!");
                } else {
                    int err = Hd_GetSDKLastError();
                    logs.Add(string.Format("  [CẢNH BÁO] Nạp qua SDK trả về mã {0} (Err: {1}).", res, err));
                }
            } else {
                logs.Add(string.Format("  [LỖI] Không thể kết nối tới card Wi-Fi: {0}", ssid));
            }

            if (!string.IsNullOrEmpty(originalWifi) && !originalWifi.StartsWith("WF2_")) {
                logs.Add(string.Format(">>> Đang trả lại kết nối Wi-Fi ban đầu: [{0}]...", originalWifi));
                ConnectWifi(originalWifi);
            }

            SendJsonResult(stream, success, success ? "Đã nạp cấu hình phần cứng thành công!" : "Lỗi khi nạp cấu hình phần cứng", success ? 0 : -1, logs.ToArray());
        }

        // =========================================================================
        // HÀM TẠO FILE XML CHUẨN HD2020 CHO ĐẦY ĐỦ HIỆU ỨNG (COLORFUL WORDS, BORDER, PULL UPWARD...)
        // =========================================================================
        private static string GetColorfulWordPath(int index) {
            string baseDir = Path.Combine(hdInstallDir, "images", "Colorfulwords");
            switch (index) {
                case 1: return Path.Combine(baseDir, "300 (1).gif");
                case 2: return Path.Combine(baseDir, "300 (2).gif");
                case 3: return Path.Combine(baseDir, "300 (3).gif");
                case 4: return Path.Combine(baseDir, "01.gif");
                case 5: return Path.Combine(baseDir, "02.gif");
                case 6: return Path.Combine(baseDir, "03.gif");
                case 7: return Path.Combine(baseDir, "04.gif");
                case 8: return Path.Combine(baseDir, "05.gif");
                default: return "";
            }
        }

        private static string GetBorderPath(int index) {
            if (index <= 0) return null;
            string baseDir = Path.Combine(hdInstallDir, "images", "Border");
            string fileName = string.Format("{0:D3}.png", index);
            string fullPath = Path.Combine(baseDir, fileName);
            return File.Exists(fullPath) ? fullPath : null;
        }

        private static string GenerateRtfContent(string text, string colorName, string alignH, int fontSize, bool bold, bool italic, bool underline) {
            string alignTag = "\\qc";
            if (alignH == "left") alignTag = "\\ql";
            else if (alignH == "right") alignTag = "\\qr";

            string styleTags = "";
            if (bold) styleTags += "\\b";
            if (italic) styleTags += "\\i";
            if (underline) styleTags += "\\ul";

            int colorIndex = 1;
            switch (colorName.ToLower()) {
                case "red": colorIndex = 1; break;
                case "green": colorIndex = 2; break;
                case "yellow": colorIndex = 3; break;
                case "blue": colorIndex = 4; break;
                case "cyan": colorIndex = 5; break;
                case "magenta": colorIndex = 6; break;
                case "white": colorIndex = 7; break;
                default: colorIndex = 2; break;
            }

            int rtfFs = fontSize > 0 ? fontSize + 4 : 20;

            string rtf = string.Format(
                "{{\\rtf1\\fbidis\\ansi\\ansicpg0\\uc1\\deff0\\deflang0\\deflangfe0{{\\fonttbl{{\\f0\\fnil Arial;}}}}{{\\colortbl;\\red255\\green0\\blue0;\\red0\\green255\\blue0;\\red255\\green255\\blue0;\\red0\\green0\\blue255;\\red0\\green255\\blue255;\\red255\\green0\\blue255;\\red255\\green255\\blue255;\\red0\\green0\\blue0;}}\\pard\\fi0\\li0{0}\\ri0\\sb0\\sa0\\itap0 \\plain \\f0\\fs{1}\\cf{2}{3} {4}\\par}}",
                alignTag, rtfFs, colorIndex, styleTags, text);

            return Convert.ToBase64String(Encoding.ASCII.GetBytes(rtf));
        }

        private static string GenerateScreenXml(BoardItem b) {
            string templateXml = @"<?xml version=""1.0"" encoding=""UTF-8""?>
<screen nodeName=""Screen1"" nodeType=""Controller_Plugin"" nodeChildType="""" isReturn=""0"" nodeChecked=""1"" nodeExpanded=""1"" nodeZ=""0"" nodeSelected=""0"" saveFileName=""generated_screen"" objMachineParams.cardType=""142"" objMachineParams.color=""2"" objMachineParams.gray=""1"" objMachineParams.width=""64"" objMachineParams.height=""32"" objMachineParams.dataPola=""1"" objMachineParams.oePola=""0"" objMachineParams.screenType=""0"" objMachineParams.smartSettingFileID=""1793777106"" objMachineParams.colockFrequency=""1"" objMachineParams.dataMirror=""0"" objMachineParams.clkMirror=""0"" objMachineParams.lineBlanking=""80"" objMachineParams.playMode=""0"" objMachineParams.icType=""0"" objMachineParams.arrBTNSetting0=""0"" objMachineParams.arrBTNSetting1=""1"" objMachineParams.arrBTNSetting2=""2"" objMachineParams.arrBTNSetting3=""6"" objMachineParams.rememberPreProgram=""0"" objMachineParams.bootingSec=""0"" objMachineParams.firstMode=""1"" objMachineParams.useTimerSwitch=""0"" objMachineParams.bootuUpTime=""21600"" objMachineParams.shutDownTime=""79200"" objMachineParams.brightnessMode=""0"" objMachineParams.customBrightValue=""49"" objMachineParams.arrUseBright0=""0"" objMachineParams.arrUseBright1=""0"" objMachineParams.arrUseBright2=""0"" objMachineParams.arrBrightValue0=""49"" objMachineParams.arrBrightValue1=""49"" objMachineParams.arrBrightValue2=""49"" objMachineParams.arrBrightTime0=""0"" objMachineParams.arrBrightTime1=""0"" objMachineParams.arrBrightTime2=""0"" objMachineParams.topX=""4"" objMachineParams.topY=""0"" objMachineParams.topWidth=""8"" objMachineParams.topHeight=""8"" objMachineParams.centerX=""0"" objMachineParams.centerY=""8"" objMachineParams.centerWidth=""16"" objMachineParams.centerHeight=""8"" objMachineParams.bottomX=""4"" objMachineParams.bottomY=""16"" objMachineParams.bottomWidth=""8"" objMachineParams.bottomHeight=""8"" objMachineParams.refreshFrequency=""1"" objMachineParams.doubleSidedScreen=""0"" objMachineParams.useSendSingleProgramMode=""0"" objMachineParams.decoder=""1"" objMachineParams.expand=""0"" objMachineParams.dutyCycle=""0"" objMachineParams.phase=""0"" objMachineParams.maxDataLength=""0"" objUserParams.guid=""{0}"" objUserParams.nZoom=""3"" objUserParams.strDeviceName=""{1}"" objUserParams.screenName=""Screen1"" objUserParams.strStartUpImagePath="""" objUserParams.bUseStartUpImage=""0"" objUserParams.nScanbufSize=""0"" objUserParams.nBootTipType=""3"" objUserParams.crossUnitWidth=""32"" objUserParams.crossUnitHeight=""16"">
    <program nodeName=""Program1"" nodeType=""programPlugin"" nodeChildType="""" isReturn=""0"" nodeChecked=""1"" nodeExpanded=""1"" nodeZ=""0"" nodeSelected=""0"" programType=""0"" playMode=""0"" playLength=""600"" arrWeekPlay0=""1"" arrWeekPlay1=""1"" arrWeekPlay2=""1"" arrWeekPlay3=""1"" arrWeekPlay4=""1"" arrWeekPlay5=""1"" arrWeekPlay6=""1"" specifedTimeEnabled=""0"" timeStart=""0"" timeEnd=""86399"" specifedDateEnabled=""0"" dateStart=""1793725200"" dateEnd=""1794330000"" buttonCtrlIndex=""255"" objBorderParams.nBorderType=""0"" objBorderParams.nType=""0"" objBorderParams.nSpeed=""{3}"" objBorderParams.nEffect=""0"" objBorderParams.nLineWidth=""0"" objBorderParams.nLineHeight=""0"" objBorderParams.strData="""" objBorderParams.nPurityIndex=""0"" objBorderParams.ColorPurityBorder=""255"" objBorderParams.nMotleyIndex=""0"" objBorderParams.nTricolorIndex=""0"" objBorderParams.IndexCustom=""0"" objBorderParams.IndexColorful=""0"" objBorderParams.bEnableBorder=""{4}"" objBorderParams.bRandomEffect=""0"" objBorderParams.nRandomHeight=""1"" objBorderParams.nRandomEffectCount=""0"" objBorderParams.d3dIsUseBy3D=""0"" objBorderParams.d3dBorderAngleValue=""10"" objBorderParams.d3dnShowBorderFlag=""255"" objBorderParams.d3dnBorderStyle=""0"" objBorderParams.d3dBorderPathImagePath=""{5}"" objBorderParams.bSpecialMode=""0"" objBorderParams.bUseSpecialBorder=""0"">
        <area nodeName=""Text1"" nodeType=""framePlugin"" nodeChildType=""textPlugin"" isReturn=""0"" nodeChecked=""1"" nodeExpanded=""1"" nodeZ=""0"" nodeSelected=""1"" rectArea_left=""0"" rectArea_top=""0"" rectArea_width=""64"" rectArea_height=""32"" nZoom=""3"" bUseBG=""0"" bTempDataFlag=""0"" bUseColorful=""0"" bUseForeground=""0"" tempGuid=""{2}"" isChanged=""0"" bLock=""0"" objBorderParams.nBorderType=""0"" objBorderParams.nType=""0"" objBorderParams.nSpeed=""{3}"" objBorderParams.nEffect=""0"" objBorderParams.nLineWidth=""0"" objBorderParams.nLineHeight=""0"" objBorderParams.strData="""" objBorderParams.nPurityIndex=""0"" objBorderParams.ColorPurityBorder=""255"" objBorderParams.nMotleyIndex=""0"" objBorderParams.nTricolorIndex=""0"" objBorderParams.IndexCustom=""0"" objBorderParams.IndexColorful=""0"" objBorderParams.bEnableBorder=""{4}"" objBorderParams.bRandomEffect=""0"" objBorderParams.nRandomHeight=""1"" objBorderParams.nRandomEffectCount=""0"" objBorderParams.d3dIsUseBy3D=""0"" objBorderParams.d3dBorderAngleValue=""10"" objBorderParams.d3dnShowBorderFlag=""255"" objBorderParams.d3dnBorderStyle=""0"" objBorderParams.d3dBorderPathImagePath=""{5}"" objBorderParams.bSpecialMode=""0"" objBorderParams.bUseSpecialBorder=""0"" objBgParams.bUseBG=""0"" objBgParams.nEffectID=""19"" objBgParams.nImgID=""4"" objBgParams.nSpeed=""5"" objBgParams.nImgCount=""0"" objBgParams.bgImgColor=""0"" objBgParams.bUseColorfulBg=""{6}"" objBgParams.bUseBorder=""0"" objBgParams.bUseImageBg=""0"" objBgParams.bUseFg=""0"" objBgParams.strColorfulBgPath=""{7}"" objBgParams.strBorderMaskPath="""" objBgParams.strBorderPath="""" objBgParams.strImagBgPath="""" objBgParams.strFgPath="""" objBgParams.nColorfulBgSpeed=""5"" objBgParams.nBorderSpeed=""5"" objBgParams.nImageBgSpeed=""5"" objBgParams.nFgSpeed=""5"" objBgParams.nBgAlpha=""255"" objBgParams.nFgAlpha=""255"" objBgParams.nBorderEffect=""0"">
            <text nodeName="""" nodeType=""textPlugin"" nodeChildType="""" isReturn=""0"" nodeChecked=""1"" nodeExpanded=""1"" nodeZ=""0"" nodeSelected=""0"" allPaths="""" x=""0"" y=""0"" width=""64"" height=""32"" vAlign=""{8}"" textDirection=""0"" whirlIndex=""0"" xOffset=""0"" yOffset=""0"" hZoom=""0"" vZoom=""0"" showEffect=""{9}"" showSpeed=""{10}"" clearType=""201"" stayTime=""{11}"" playtime=""1"" useColorInversion=""{12}"" useEmpty=""{13}"" useOutline=""{14}"" outlineSize=""{15}"" outlineColor=""255"" supportBeginToEnd=""0"" plainText="""" rtfData=""{16}""/>
        </area>
    </program>
</screen>";

            string borderPath = GetBorderPath(b.BorderStyle);
            bool borderEnabled = !string.IsNullOrEmpty(borderPath);

            string colorfulPath = GetColorfulWordPath(b.ColorfulWords);
            bool colorfulEnabled = !string.IsNullOrEmpty(colorfulPath);

            string vAlignVal = "1"; // Middle
            if (b.AlignV == "top") vAlignVal = "0";
            else if (b.AlignV == "bottom") vAlignVal = "2";

            int effectVal = b.Effect;
            int speedVal = b.Speed > 0 ? b.Speed : 10;
            int stayVal = b.StayTime >= 0 ? b.StayTime : 3;

            string base64Rtf = GenerateRtfContent(b.Text, b.Color, b.AlignH, b.FontSize, b.Bold, b.Italic, b.Underline);

            string xml = string.Format(templateXml,
                "{7100ff00-b1fa-0d00-2000-01da8300001a}", // 0: GUID
                b.Ssid,                                   // 1: Device SSID
                Guid.NewGuid().ToString("B"),             // 2: Temp GUID
                b.BorderSpeed,                            // 3: Border speed
                borderEnabled ? "1" : "0",                // 4: Border enable
                borderPath.Replace("\\", "/"),            // 5: Border image path
                colorfulEnabled ? "1" : "0",              // 6: Colorful word enable
                colorfulPath.Replace("\\", "/"),          // 7: Colorful word path
                vAlignVal,                                // 8: vAlign
                effectVal,                                // 9: showEffect
                speedVal,                                 // 10: showSpeed
                stayVal,                                  // 11: stayTime
                b.Invert ? "1" : "0",                     // 12: Invert
                b.Hollow ? "1" : "0",                     // 13: Hollow
                b.Stroke ? "1" : "0",                     // 14: Stroke
                b.StrokeWidth,                            // 15: Outline size
                base64Rtf                                 // 16: RTF Data
            );

            string tempFile = Path.Combine(Path.GetTempPath(), "screen_" + b.Ssid + ".xml");
            File.WriteAllText(tempFile, xml, Encoding.UTF8);
            return tempFile;
        }

        // =========================================================================
        // HÀM TẠO ẢNH BITMAP CHUẨN HD2020 - CĂN GIỮA TUYỆT ĐỐI TỪNG PIXEL, FULL 7 MÀU & VIỀN 1PX
        // =========================================================================
        private static Color GetGdiColor(string colorName) {
            if (string.IsNullOrEmpty(colorName)) return Color.FromArgb(0, 255, 0);
            switch (colorName.ToLower()) {
                case "red": return Color.FromArgb(255, 0, 0);
                case "green": return Color.FromArgb(0, 255, 0);
                case "blue": return Color.FromArgb(0, 0, 255);
                case "yellow": return Color.FromArgb(255, 255, 0);
                case "purple":
                case "magenta": return Color.FromArgb(255, 0, 255);
                case "cyan": return Color.FromArgb(0, 255, 255);
                case "white": return Color.FromArgb(255, 255, 255);
                case "orange": return Color.FromArgb(255, 255, 0);
                default: return Color.FromArgb(0, 255, 0);
            }
        }

        // Bảng màu thuần 1-bit RGB (Không bao giờ bị mất nét khi HDSDK chuyển sang 1-bit gray=1)
        private static Color GetPureRainbowColor(int preset, int x, int y, int width, int height) {
            Color cRed = Color.FromArgb(255, 0, 0);
            Color cYellow = Color.FromArgb(255, 255, 0);
            Color cGreen = Color.FromArgb(0, 255, 0);
            Color cCyan = Color.FromArgb(0, 255, 255);
            Color cBlue = Color.FromArgb(0, 0, 255);
            Color cMagenta = Color.FromArgb(255, 0, 255);
            Color cWhite = Color.FromArgb(255, 255, 255);

            Color[] palette;
            int span = Math.Max(1, width);
            int pos = x;

            switch (preset) {
                case 1: // Cầu vồng 7 màu ngang chuẩn HD2020
                    palette = new Color[] { cRed, cYellow, cGreen, cCyan, cBlue, cMagenta };
                    break;
                case 2: // Cầu vồng dọc
                    palette = new Color[] { cRed, cYellow, cGreen, cCyan, cMagenta };
                    span = Math.Max(1, height);
                    pos = y;
                    break;
                case 3: // Sóng Neon chéo
                    palette = new Color[] { cMagenta, cCyan, cYellow, cGreen, cRed };
                    span = Math.Max(1, width + height);
                    pos = x + y;
                    break;
                case 4: // Hoàng hôn Đỏ - Vàng - Tím - Xanh ngọc
                    palette = new Color[] { cRed, cYellow, cMagenta, cCyan };
                    break;
                case 5: // Biển Xanh ngọc - Trắng - Xanh dương
                    palette = new Color[] { cCyan, cWhite, cBlue, cCyan };
                    break;
                case 6: // Lửa Đỏ - Vàng - Trắng
                    palette = new Color[] { cRed, cYellow, cWhite, cYellow, cRed };
                    break;
                case 7: // Đa sắc Rực rỡ
                    palette = new Color[] { cGreen, cYellow, cCyan, cMagenta, cRed };
                    break;
                default: // Cyberpunk Tím - Vàng - Xanh ngọc
                    palette = new Color[] { cMagenta, cYellow, cCyan, cGreen };
                    break;
            }

            int idx = (pos * palette.Length) / span;
            if (idx < 0) idx = 0;
            if (idx >= palette.Length) idx = palette.Length - 1;
            return palette[idx];
        }

        // Sinh file ảnh dải viền 64x1 pixel chuẩn phần cứng HD2020 cho Hd_AddProgram (chạy quanh viền độc lập)
        private static string GenerateBorderStripBitmap(int borderStyle) {
            if (borderStyle <= 0) return null;
            Color cRed = Color.FromArgb(255, 0, 0);
            Color cYellow = Color.FromArgb(255, 255, 0);
            Color cGreen = Color.FromArgb(0, 255, 0);
            Color cCyan = Color.FromArgb(0, 255, 255);
            Color cBlue = Color.FromArgb(0, 0, 255);
            Color cMagenta = Color.FromArgb(255, 0, 255);
            Color cWhite = Color.FromArgb(255, 255, 255);
            Color cBlack = Color.Black;

            Color[] pattern;
            switch (borderStyle) {
                case 1: // Mẫu 001: Chấm bi Đỏ - Vàng - Lục
                    pattern = new Color[] { cRed, cRed, cBlack, cYellow, cYellow, cBlack, cGreen, cGreen, cBlack };
                    break;
                case 2: // Mẫu 002: Sao lấp lánh Trắng - Xanh ngọc
                    pattern = new Color[] { cWhite, cCyan, cBlack, cCyan };
                    break;
                case 3: // Mẫu 003: Sóng 7 màu liên tục
                    pattern = new Color[] { cRed, cRed, cYellow, cYellow, cGreen, cGreen, cCyan, cCyan, cBlue, cBlue, cMagenta, cMagenta };
                    break;
                case 4: // Mẫu 004: Viền đa sắc Đỏ - Lục - Lam
                    pattern = new Color[] { cRed, cRed, cRed, cBlack, cGreen, cGreen, cGreen, cBlack, cBlue, cBlue, cBlue, cBlack };
                    break;
                case 5: // Mẫu 005: Kim cương Tím - Xanh ngọc
                    pattern = new Color[] { cMagenta, cMagenta, cMagenta, cBlack, cCyan, cCyan, cCyan, cBlack };
                    break;
                case 6: // Mẫu 006: Đường gạch neon Vàng - Đỏ
                    pattern = new Color[] { cYellow, cYellow, cYellow, cBlack, cRed, cRed, cRed, cBlack };
                    break;
                default: // Mẫu 007: Vệt sao băng Xanh lá - Vàng
                    pattern = new Color[] { cGreen, cGreen, cGreen, cYellow, cYellow, cBlack };
                    break;
            }

            try {
                string stripFile = Path.Combine(Path.GetTempPath(), "bdr_" + Guid.NewGuid().ToString("N") + ".bmp");
                using (Bitmap b = new Bitmap(64, 1, PixelFormat.Format24bppRgb)) {
                    for (int x = 0; x < 64; x++) {
                        b.SetPixel(x, 0, pattern[x % pattern.Length]);
                    }
                    b.Save(stripFile, ImageFormat.Bmp);
                }
                return stripFile;
            } catch {
                return null;
            }
        }

        private static List<string> GenerateLedBitmapPages(BoardItem b, out int outW, out int outH, out int usedFont) {
            List<string> pages = new List<string>();
            // QUY TẮC PHẦN CỨNG HD-WF2:
            // - Khi có Viền chạy (BorderStyle > 0): Khung chữ bên trong là 62x30, viền chạy quanh viền 64x32 độc lập ở Program level!
            // - Khi không viền (BorderStyle == 0): Toàn màn hình 64x32.
            int canvasW = (b.BorderStyle > 0) ? 62 : 64;
            int canvasH = (b.BorderStyle > 0) ? 30 : 32;
            outW = canvasW;
            outH = canvasH;

            int safeW = (b.BorderStyle > 0) ? 60 : 62;
            int safeH = (b.BorderStyle > 0) ? 28 : 30;

            string text = string.IsNullOrEmpty(b.Text) ? " " : b.Text.Trim();
            int reqFont = b.FontSize > 0 ? b.FontSize : 16;
            usedFont = reqFont;

            try {
                FontStyle style = FontStyle.Regular;
                if (b.Bold) style |= FontStyle.Bold;
                if (b.Italic) style |= FontStyle.Italic;
                if (b.Underline) style |= FontStyle.Underline;

                int curSize = reqFont;
                int minX = 0, maxX = -1, minY = 0, maxY = -1;
                Bitmap maskBmp = null;

                // Tự động co cỡ chữ vừa khít vùng an toàn safeW x safeH nếu là từ đơn / tên ngắn
                while (curSize >= 8) {
                    if (maskBmp != null) maskBmp.Dispose();
                    maskBmp = new Bitmap(512, 64, PixelFormat.Format24bppRgb);
                    using (Graphics g = Graphics.FromImage(maskBmp))
                    using (Font f = new Font("Arial", curSize, style, GraphicsUnit.Pixel)) {
                        g.Clear(Color.Black);
                        g.SmoothingMode = SmoothingMode.None;
                        g.InterpolationMode = InterpolationMode.NearestNeighbor;
                        g.TextRenderingHint = TextRenderingHint.SingleBitPerPixelGridFit;
                        g.DrawString(text, f, Brushes.White, 10, 10, StringFormat.GenericTypographic);
                    }

                    minX = 9999; maxX = -1; minY = 9999; maxY = -1;
                    for (int y = 0; y < maskBmp.Height; y++) {
                        for (int x = 0; x < maskBmp.Width; x++) {
                            Color c = maskBmp.GetPixel(x, y);
                            if (c.R > 128 || c.G > 128 || c.B > 128) {
                                if (x < minX) minX = x;
                                if (x > maxX) maxX = x;
                                if (y < minY) minY = y;
                                if (y > maxY) maxY = y;
                            }
                        }
                    }

                    int tw = (maxX >= minX) ? (maxX - minX + 1) : 0;
                    int th = (maxY >= minY) ? (maxY - minY + 1) : 0;
                    usedFont = curSize;

                    if (th > safeH && curSize > 8) {
                        curSize--;
                        continue;
                    }
                    if (tw > safeW && tw <= safeW * 1.5 && text.Length <= 12 && curSize > 8) {
                        curSize--;
                        continue;
                    }
                    break;
                }

                int tightW = (maxX >= minX) ? (maxX - minX + 1) : 1;
                int tightH = (maxY >= minY) ? (maxY - minY + 1) : 1;

                using (Bitmap coloredTight = new Bitmap(tightW, tightH, PixelFormat.Format24bppRgb)) {
                    Color solidColor = GetGdiColor(b.Color);
                    Color strokeColor = GetGdiColor(b.StrokeColor);

                    bool[,] lit = new bool[tightW, tightH];
                    for (int ty = 0; ty < tightH; ty++) {
                        for (int tx = 0; tx < tightW; tx++) {
                            if (maxX >= minX) {
                                Color mc = maskBmp.GetPixel(minX + tx, minY + ty);
                                lit[tx, ty] = (mc.R > 128 || mc.G > 128 || mc.B > 128);
                            }
                        }
                    }

                    for (int ty = 0; ty < tightH; ty++) {
                        for (int tx = 0; tx < tightW; tx++) {
                            bool isLit = lit[tx, ty];
                            bool isEdge = false;
                            if (isLit) {
                                if (tx == 0 || tx == tightW - 1 || ty == 0 || ty == tightH - 1 ||
                                    !lit[tx - 1, ty] || !lit[tx + 1, ty] || !lit[tx, ty - 1] || !lit[tx, ty + 1]) {
                                    isEdge = true;
                                }
                            }

                            Color pxColor = Color.Black;
                            if (isLit) {
                                // Tô chuẩn 100% Chữ 7 màu [AB] rực rỡ hoặc Màu đơn sắc đã chọn (TUYỆT ĐỐI KHÔNG BỊ MÀU TRẮNG!)
                                Color fillClr = (b.ColorfulWords > 0)
                                    ? GetPureRainbowColor(b.ColorfulWords, tx, ty, tightW, tightH)
                                    : solidColor;

                                if (b.Hollow) {
                                    pxColor = isEdge ? fillClr : Color.Black;
                                } else if (b.Stroke) {
                                    pxColor = isEdge ? strokeColor : fillClr;
                                } else {
                                    pxColor = fillClr;
                                }
                            }

                            if (b.Invert) {
                                pxColor = Color.FromArgb(255 - pxColor.R, 255 - pxColor.G, 255 - pxColor.B);
                            }
                            coloredTight.SetPixel(tx, ty, pxColor);
                        }
                    }

                    if (maskBmp != null) maskBmp.Dispose();

                    int marginY = (b.BorderStyle > 0) ? 2 : 1;
                    int destY = (canvasH - tightH) / 2;
                    if (b.AlignV == "top") destY = marginY;
                    else if (b.AlignV == "bottom") destY = Math.Max(marginY, canvasH - tightH - marginY);
                    else destY = Math.Max(marginY, (canvasH - tightH) / 2);

                    int marginX = (b.BorderStyle > 0) ? 2 : 1;
                    if (tightW <= safeW) {
                        int destX = (canvasW - tightW) / 2;
                        if (b.AlignH == "left") destX = marginX;
                        else if (b.AlignH == "right") destX = Math.Max(marginX, canvasW - tightW - marginX);
                        else destX = Math.Max(marginX, (canvasW - tightW) / 2);

                        string pageFile = Path.Combine(Path.GetTempPath(), "led_" + Guid.NewGuid().ToString("N") + ".bmp");
                        using (Bitmap pageBmp = new Bitmap(canvasW, canvasH, PixelFormat.Format24bppRgb)) {
                            for (int y = 0; y < canvasH; y++) {
                                for (int x = 0; x < canvasW; x++) {
                                    pageBmp.SetPixel(x, y, b.Invert ? solidColor : Color.Black);
                                }
                            }
                            for (int ty = 0; ty < tightH; ty++) {
                                int py = destY + ty;
                                if (py >= 0 && py < canvasH) {
                                    for (int tx = 0; tx < tightW; tx++) {
                                        int px = destX + tx;
                                        if (px >= 0 && px < canvasW) {
                                            pageBmp.SetPixel(px, py, coloredTight.GetPixel(tx, ty));
                                        }
                                    }
                                }
                            }
                            pageBmp.Save(pageFile, ImageFormat.Bmp);
                        }
                        pages.Add(pageFile);
                    } else {
                        int pageCount = (int)Math.Ceiling((double)tightW / safeW);
                        for (int p = 0; p < pageCount; p++) {
                            int srcStartX = p * safeW;
                            string pageFile = Path.Combine(Path.GetTempPath(), "led_" + Guid.NewGuid().ToString("N") + "_p" + p + ".bmp");
                            using (Bitmap pageBmp = new Bitmap(canvasW, canvasH, PixelFormat.Format24bppRgb)) {
                                for (int y = 0; y < canvasH; y++) {
                                    for (int x = 0; x < canvasW; x++) {
                                        pageBmp.SetPixel(x, y, Color.Black);
                                    }
                                }
                                for (int ty = 0; ty < tightH; ty++) {
                                    int py = destY + ty;
                                    if (py >= 0 && py < canvasH) {
                                        for (int sx = 0; sx < safeW; sx++) {
                                            int tx = srcStartX + sx;
                                            int px = marginX + sx;
                                            if (tx < tightW && px >= 0 && px < canvasW) {
                                                pageBmp.SetPixel(px, py, coloredTight.GetPixel(tx, ty));
                                            }
                                        }
                                    }
                                }
                                pageBmp.Save(pageFile, ImageFormat.Bmp);
                            }
                            pages.Add(pageFile);
                        }
                    }
                }
            } catch (Exception ex) {
                Console.WriteLine("[ERROR] GenerateLedBitmapPages loi: " + ex.Message);
            }

            return pages;
        }

        // =========================================================================
        // HÀM GỬI DỮ LIỆU LED V18 PRO - VIỀN CHẠY QUANH BẢNG ĐỘC LẬP CHUẨN HD2020 & 7 MÀU [AB]
        // =========================================================================
        private static int SendScreenData(BoardItem b, string ip, out string areaDebugInfo) {
            areaDebugInfo = "";

            int bmpW = 64;
            int bmpH = 32;
            int usedFont = b.FontSize;
            List<string> pageBmps = GenerateLedBitmapPages(b, out bmpW, out bmpH, out usedFont);
            if (pageBmps == null || pageBmps.Count == 0) {
                areaDebugInfo = "Không tạo được file ảnh bitmap";
                return -1;
            }

            // Lưu bản sao ảnh thực tế gửi xuống card (để kiểm tra màu chữ khi cần): web_control\debug_<SSID>.bmp
            try { File.Copy(pageBmps[0], Path.Combine(appDir, "debug_" + b.Ssid + ".bmp"), true); } catch {}

            string borderStripFile = null;
            if (b.BorderStyle > 0) {
                borderStripFile = GenerateBorderStripBitmap(b.BorderStyle);
            }

            try {
                int nScreen = Hd_CreateScreen(64, 32, 2, 1, 142, IntPtr.Zero, 0);
                if (nScreen != 0) {
                    areaDebugInfo = "Hd_CreateScreen thất bại: " + nScreen;
                    return Hd_GetSDKLastError();
                }

                int borderEff = (b.BorderMode != null && b.BorderMode.Equals("Anti-clockwise", StringComparison.OrdinalIgnoreCase)) ? 1 : 0;
                int borderSpd = b.BorderSpeed > 0 ? b.BorderSpeed : 5;

                // Nạp Viền chạy chuẩn phần cứng HD2020: chạy quanh viền độc lập, không cuộn theo chữ!
                int nProgID = Hd_AddProgram(borderStripFile, borderEff, borderSpd, IntPtr.Zero, 0);
                if (nProgID < 0) {
                    areaDebugInfo = "Hd_AddProgram thất bại: " + nProgID;
                    return Hd_GetSDKLastError();
                }

                int directEff = b.Effect;
                int directStayTime = b.StayTime > 0 ? b.StayTime : 3;
                int clearType = 201; // 201 (0x00C9) = "Do not clear" chuẩn HD2020 giúp hiệu ứng mượt không chớp tắt

                if (b.Effect == 202) {
                    directEff = 1; // Move Left
                    directStayTime = b.StayTime > 0 ? b.StayTime : 1;
                } else if (b.Effect == 203) {
                    directEff = 2; // Move Right
                    directStayTime = b.StayTime > 0 ? b.StayTime : 1;
                } else if (b.Effect == 200) {
                    directEff = 38; // Pull vertically
                    directStayTime = b.StayTime > 0 ? b.StayTime : 3;
                } else if (b.Effect < 0 || b.Effect > 45) {
                    directEff = 1;
                    directStayTime = b.StayTime > 0 ? b.StayTime : 3;
                }

                int speed = b.Speed > 0 ? b.Speed : 10;

                // Khi có viền: Khung chữ là 62x30 (X=1, Y=1). Khi không viền: Khung chữ là 64x32 (X=0, Y=0).
                int areaX = (b.BorderStyle > 0) ? 1 : 0;
                int areaY = (b.BorderStyle > 0) ? 1 : 0;
                int areaW = (b.BorderStyle > 0) ? 62 : 64;
                int areaH = (b.BorderStyle > 0) ? 30 : 32;

                int nAreaID = Hd_AddArea(nProgID, areaX, areaY, areaW, areaH, null, 0, 0, IntPtr.Zero, 0);
                if (nAreaID < 0) {
                    areaDebugInfo = "Hd_AddArea thất bại: " + nAreaID;
                    return Hd_GetSDKLastError();
                }

                foreach (string pageBmp in pageBmps) {
                    int nItem = Hd_AddImageAreaItem(nAreaID, pageBmp, directEff, speed, clearType, directStayTime, IntPtr.Zero, 0);
                    if (nItem < 0) {
                        areaDebugInfo = "Hd_AddImageAreaItem thất bại: " + nItem;
                        return Hd_GetSDKLastError();
                    }
                }

                areaDebugInfo = string.Format("Chuẩn HD2020 V18: Khung={0}x{1}px ({2} trang), Căn:{3}/{4}, Font:{5}px, Eff:{6} (Spd:{7}, Dừng:{8}s, Clear:201), 7Màu:{9}, Viền:{10} ({11}, Spd:{12})",
                    areaW, areaH, pageBmps.Count, b.AlignH, b.AlignV, usedFont, directEff, speed, directStayTime,
                    b.ColorfulWords > 0 ? ("BẬT (Mẫu " + b.ColorfulWords + ")") : ("TẮT (" + b.Color.ToUpper() + ")"),
                    b.BorderStyle > 0 ? ("BẬT (Mẫu " + b.BorderStyle + ")") : "TẮT",
                    b.BorderMode, borderSpd);
                Console.WriteLine("    [HD2020 ENGINE V18] " + areaDebugInfo);

                for (int sendTry = 1; sendTry <= 3; sendTry++) {
                    int res = Hd_SendScreenW(0, ip, null, IntPtr.Zero, 0);
                    if (res == 0) return 0;

                    res = Hd_SendScreenA(0, ip, null, IntPtr.Zero, 0);
                    if (res == 0) return 0;

                    if (sendTry < 3) {
                        Console.WriteLine("    [RETRY SEND] Lan " + sendTry + " chua nhan, cho 800ms gui lai lan " + (sendTry + 1) + "...");
                        Thread.Sleep(800);
                    }
                }

                int lastErr = Hd_GetSDKLastError();
                return lastErr == 0 ? -1 : lastErr;
            } finally {
                foreach (string pageBmp in pageBmps) {
                    try { if (File.Exists(pageBmp)) File.Delete(pageBmp); } catch {}
                }
                if (!string.IsNullOrEmpty(borderStripFile)) {
                    try { if (File.Exists(borderStripFile)) File.Delete(borderStripFile); } catch {}
                }
            }
        }

        private static readonly object syncLock = new object();
        private static bool syncRunning = false;
        private static bool syncSuccess = false;
        private static string syncMessage = "";
        private static List<string> syncLogs = new List<string>();
        private static List<BoardItem> lastKnownBoards = new List<BoardItem>();

        private static void AppendSyncLog(string msg) {
            Console.WriteLine(msg);
            lock (syncLock) {
                syncLogs.Add(msg);
            }
        }

        private static void HandleApiSendStatus(NetworkStream stream) {
            bool running;
            bool success;
            string message;
            string[] logsArr;
            lock (syncLock) {
                running = syncRunning;
                success = syncSuccess;
                message = syncMessage;
                logsArr = syncLogs.ToArray();
            }

            StringBuilder sb = new StringBuilder();
            sb.Append("{");
            sb.Append("\"running\":").Append(running ? "true" : "false").Append(",");
            sb.Append("\"success\":").Append(success ? "true" : "false").Append(",");
            sb.Append("\"message\":\"").Append(EscapeJson(message)).Append("\",");
            sb.Append("\"logs\":[");
            for (int i = 0; i < logsArr.Length; i++) {
                if (i > 0) sb.Append(",");
                sb.Append("\"").Append(EscapeJson(logsArr[i])).Append("\"");
            }
            sb.Append("]}");

            byte[] b = Encoding.UTF8.GetBytes(sb.ToString());
            SendHttpResponse(stream, 200, "OK", "application/json; charset=utf-8", b);
        }

        private static List<BoardItem> ParseBoardsJson(string body) {
            List<BoardItem> list = new List<BoardItem>();
            try {
                int boardsIdx = body.IndexOf("\"boards\"");
                if (boardsIdx >= 0) {
                    int startArr = body.IndexOf('[', boardsIdx);
                    int endArr = body.LastIndexOf(']');
                    if (startArr >= 0 && endArr > startArr) {
                        string arrContent = body.Substring(startArr + 1, endArr - startArr - 1);
                        int depth = 0;
                        int objStart = -1;
                        for (int i = 0; i < arrContent.Length; i++) {
                            if (arrContent[i] == '{') {
                                if (depth == 0) objStart = i;
                                depth++;
                            } else if (arrContent[i] == '}') {
                                depth--;
                                if (depth == 0 && objStart >= 0) {
                                    string objStr = arrContent.Substring(objStart, i - objStart + 1);
                                    BoardItem b = new BoardItem();

                                    int id = 0;
                                    int.TryParse(GetJsonValue(objStr, "id"), out id);
                                    b.Id = id > 0 ? id : list.Count + 1;

                                    b.Name = GetJsonValue(objStr, "name");
                                    if (string.IsNullOrEmpty(b.Name)) b.Name = "BẢNG " + b.Id;

                                    b.Ssid = GetJsonValue(objStr, "ssid");
                                    b.Text = GetJsonValue(objStr, "text").Replace("\\r\\n", "\r\n").Replace("\\n", "\r\n");

                                    string col = GetJsonValue(objStr, "color");
                                    b.Color = !string.IsNullOrEmpty(col) ? col : "green";

                                    int fs = 16;
                                    int.TryParse(GetJsonValue(objStr, "fontSize"), out fs);
                                    b.FontSize = fs > 0 ? fs : 16;

                                    string alH = GetJsonValue(objStr, "alignH");
                                    b.AlignH = !string.IsNullOrEmpty(alH) ? alH : "center";

                                    string alV = GetJsonValue(objStr, "alignV");
                                    b.AlignV = !string.IsNullOrEmpty(alV) ? alV : "middle";

                                    int eff = 0;
                                    int.TryParse(GetJsonValue(objStr, "effect"), out eff);
                                    b.Effect = eff;

                                    int sp = 10;
                                    int.TryParse(GetJsonValue(objStr, "speed"), out sp);
                                    b.Speed = sp > 0 ? sp : 10;

                                    int st = 3;
                                    int.TryParse(GetJsonValue(objStr, "stayTime"), out st);
                                    b.StayTime = st >= 0 ? st : 3;

                                    int cw = 0;
                                    int.TryParse(GetJsonValue(objStr, "colorfulWords"), out cw);
                                    b.ColorfulWords = cw;

                                    b.Hollow = GetJsonValue(objStr, "hollow") == "true";
                                    b.Stroke = GetJsonValue(objStr, "stroke") == "true";
                                    int sw = 1;
                                    int.TryParse(GetJsonValue(objStr, "strokeWidth"), out sw);
                                    b.StrokeWidth = sw > 0 ? sw : 1;
                                    b.StrokeColor = GetJsonValue(objStr, "strokeColor");
                                    if (string.IsNullOrEmpty(b.StrokeColor)) b.StrokeColor = "red";
                                    b.Invert = GetJsonValue(objStr, "invert") == "true";

                                    int bs = 0;
                                    int.TryParse(GetJsonValue(objStr, "borderStyle"), out bs);
                                    b.BorderStyle = bs;

                                    int bsp = 5;
                                    int.TryParse(GetJsonValue(objStr, "borderSpeed"), out bsp);
                                    b.BorderSpeed = bsp > 0 ? bsp : 5;

                                    b.BorderMode = GetJsonValue(objStr, "borderMode");
                                    if (string.IsNullOrEmpty(b.BorderMode)) b.BorderMode = "Clockwise";

                                    b.Bold = GetJsonValue(objStr, "bold") != "false";
                                    b.Italic = GetJsonValue(objStr, "italic") == "true";
                                    b.Underline = GetJsonValue(objStr, "underline") == "true";

                                    if (!string.IsNullOrEmpty(b.Ssid)) {
                                        list.Add(b);
                                    }
                                }
                            }
                        }
                    }
                }
            } catch (Exception ex) {
                Console.WriteLine("[ERROR] ParseBoardsJson loi: " + ex.Message);
            }
            return list;
        }

        private static void HandleApiSend(NetworkStream stream, string body) {
            string target = GetJsonValue(body, "target");
            if (string.IsNullOrEmpty(target)) target = "sync_all";

            string detectedOriginalWifi = GetCurrentWifiSsid();
            string originalWifi = GetJsonValue(body, "originalWifi");
            if (string.IsNullOrEmpty(originalWifi)) originalWifi = detectedOriginalWifi;

            bool reconnectBack = GetJsonValue(body, "reconnectBack") == "true";
            bool autoSwitchWifi = GetJsonValue(body, "autoSwitchWifi") != "false";

            if (!sdkLoaded) {
                SendJsonResult(stream, false, "HDSDK.dll chua duoc nap tren may!", -1, new string[] { "Lỗi nạp thư viện HDSDK.dll" });
                return;
            }

            List<BoardItem> boards = ParseBoardsJson(body);
            Console.WriteLine("[API SEND] Nhan body len=" + body.Length + " bytes, parsed boards=" + boards.Count);

            if (boards.Count > 0) {
                lock (syncLock) {
                    lastKnownBoards = new List<BoardItem>(boards);
                }
            } else {
                lock (syncLock) {
                    if (lastKnownBoards.Count > 0) {
                        boards.AddRange(lastKnownBoards);
                    }
                }
                if (boards.Count == 0) {
                    boards.Add(new BoardItem { Id = 1, Name = "BẢNG 1", Ssid = "WF2_f412fab2b75c", Text = "PHÚC", Color = "cyan", Effect = 1, Speed = 10, StayTime = 3, ColorfulWords = 1, BorderStyle = 5, BorderSpeed = 5 });
                    boards.Add(new BoardItem { Id = 2, Name = "BẢNG 2", Ssid = "WF2_1051db45b870", Text = "NGUYỄN", Color = "green", Effect = 1, Speed = 10, StayTime = 3, ColorfulWords = 1, BorderStyle = 5, BorderSpeed = 5 });
                    boards.Add(new BoardItem { Id = 3, Name = "BẢNG 3", Ssid = "WF2_f412fab177c8", Text = "HOÀNG", Color = "red", Effect = 2, Speed = 10, StayTime = 3, ColorfulWords = 1, BorderStyle = 5, BorderSpeed = 5 });
                }
            }

            List<BoardItem> targetBoards = new List<BoardItem>();
            if (target == "sync_all") {
                targetBoards.AddRange(boards);
            } else {
                foreach (var b in boards) {
                    if (target == "board_" + b.Id || target == b.Ssid || (target == "board1" && b.Id == 1) || (target == "board2" && b.Id == 2) || (target == "board3" && b.Id == 3)) {
                        targetBoards.Add(b);
                    }
                }
                if (targetBoards.Count == 0) targetBoards.AddRange(boards);
            }

            lock (syncLock) {
                if (syncRunning) {
                    byte[] busyBytes = Encoding.UTF8.GetBytes("{\"started\":true,\"async\":true,\"alreadyRunning\":true}");
                    SendHttpResponse(stream, 200, "OK", "application/json; charset=utf-8", busyBytes);
                    return;
                }
                syncRunning = true;
                syncSuccess = false;
                syncMessage = "Đang đồng bộ...";
                syncLogs.Clear();
            }

            // Trả kết quả HTTP 200 NGAY LẬP TỨC (trước khi ngắt/đổi Wi-Fi) để trình duyệt Chrome không bao giờ bị lỗi "Failed to fetch" (ERR_NETWORK_CHANGED)!
            byte[] startResp = Encoding.UTF8.GetBytes("{\"started\":true,\"async\":true,\"count\":" + targetBoards.Count + "}");
            SendHttpResponse(stream, 200, "OK", "application/json; charset=utf-8", startResp);

            ThreadPool.QueueUserWorkItem(_ => {
                // Đợi 250ms để gói phản hồi HTTP gửi xong hoàn toàn về trình duyệt trước khi chạm vào card Wi-Fi
                Thread.Sleep(250);
                bool allSuccess = true;
                try {
                    Console.WriteLine("\n============================================================");
                    Console.WriteLine("[HD2020 ENGINE V17] So luong bang can gui: " + targetBoards.Count);
                    Console.WriteLine("  -> Mang ban dau: " + (string.IsNullOrEmpty(originalWifi) ? "(Khong ro)" : originalWifi));
                    Console.WriteLine("  -> Che do tu dong doi Wi-Fi: " + (autoSwitchWifi ? "BAT" : "TAT (Giu nguyen)"));

                    AppendSyncLog(string.Format("Bắt đầu tiến trình gửi cho {0} bảng LED...", targetBoards.Count));
                    if (!string.IsNullOrEmpty(originalWifi) && !originalWifi.StartsWith("WF2_")) {
                        AppendSyncLog("Đã ghi nhớ mạng Wi-Fi ban đầu của máy: [" + originalWifi + "]");
                    }

                    for (int i = 0; i < targetBoards.Count; i++) {
                        var b = targetBoards[i];
                        string currentSsid = GetCurrentWifiSsid();

                        if (!autoSwitchWifi) {
                            AppendSyncLog(string.Format(">>> [{0}/{1}] Chế độ GIỮ NGUYÊN WI-FI: Gửi trực tiếp tới {2}...",
                                i + 1, targetBoards.Count, b.Name));
                        } else if (!string.IsNullOrEmpty(currentSsid) && string.Equals(currentSsid, b.Ssid, StringComparison.OrdinalIgnoreCase)) {
                            AppendSyncLog(string.Format(">>> [{0}/{1}] Đã kết nối đúng card {2} ({3}). Gửi ngay!",
                                i + 1, targetBoards.Count, b.Name, b.Ssid));
                        } else {
                            AppendSyncLog(string.Format(">>> [{0}/{1}] Đang kết nối {2} ({3})...", i + 1, targetBoards.Count, b.Name, b.Ssid));
                            EnsureWifiProfileForSsid(b.Ssid, "88888888");
                            ConnectWifi(b.Ssid);
                        }

                        bool boardReachable = false;
                        for (int attempt = 1; attempt <= 2; attempt++) {
                            if (WaitForBoard("192.168.4.1", 6101, attempt == 1 ? 18 : 12)) {
                                boardReachable = true;
                                break;
                            }
                            if (attempt == 1 && autoSwitchWifi) {
                                AppendSyncLog(string.Format("  [RETRY] Lần 1 chưa thông cổng, thử kết nối lại {0} lần 2...", b.Ssid));
                                ConnectWifi(b.Ssid);
                            }
                        }

                        if (boardReachable) {
                            string effDesc = "Hiệu ứng " + b.Effect;
                            if (b.Effect == 0) effDesc = "Đứng yên";
                            else if (b.Effect == 1 || b.Effect == 202) effDesc = "Chạy chữ sang trái (Move Left)";
                            else if (b.Effect == 2 || b.Effect == 203) effDesc = "Chạy chữ sang phải (Move Right)";
                            else if (b.Effect == 37 || b.Effect == 3) effDesc = "Cuộn lên trên (Pull upward)";
                            else if (b.Effect == 36 || b.Effect == 4) effDesc = "Cuộn xuống dưới (Pull downward)";
                            else if (b.Effect == 38) effDesc = "Kéo giãn dọc (Pull vertically)";
                            else if (b.Effect == 39) effDesc = "Kéo giãn ngang (Pull horizontally)";
                            else if (b.Effect == 34) effDesc = "Nhấp nháy (Twinkle)";

                            AppendSyncLog(string.Format("  -> Đã kết nối {0}. Đang nạp chữ: '{1}' (Màu: {2}, Font:{3}px, {4}, 7Màu: {5}, Viền: {6})...",
                                b.Name, b.Text, b.Color.ToUpper(), b.FontSize, effDesc, b.ColorfulWords > 0 ? "BẬT" : "TẮT", b.BorderStyle > 0 ? "BẬT" : "TẮT"));

                            string dbg;
                            int r = SendScreenData(b, "192.168.4.1", out dbg);
                            if (r == 0) {
                                AppendSyncLog(string.Format("  ===> [THÀNH CÔNG] {0} ĐÃ NHẬN HIỆU ỨNG & SÁNG CHỮ: '{1}'!", b.Name, b.Text));
                                AppendSyncLog("       (" + dbg + ")");
                            } else {
                                allSuccess = false;
                                AppendSyncLog(string.Format("  [LỖI] {0} không nhận dữ liệu. Mã lỗi: {1}", b.Name, r));
                            }
                        } else {
                            allSuccess = false;
                            AppendSyncLog(string.Format("  [THẤT BẠI] Không thể kết nối tới {0} qua Wi-Fi [{1}]. Kiểm tra card có bật nguồn không!", b.Name, b.Ssid));
                        }
                    }

                    if (reconnectBack && !string.IsNullOrEmpty(originalWifi) && !originalWifi.StartsWith("WF2_")) {
                        AppendSyncLog(string.Format(">>> Đang trả lại kết nối Wi-Fi ban đầu: [{0}]...", originalWifi));
                        ConnectWifi(originalWifi);
                    } else {
                        AppendSyncLog(">>> Giữ nguyên kết nối Wi-Fi hiện tại của máy tính (Không ép đổi mạng).");
                    }
                } catch (Exception ex) {
                    allSuccess = false;
                    AppendSyncLog("[LỖI HỆ THỐNG] " + ex.Message);
                } finally {
                    string finalMsg = allSuccess
                        ? string.Format("HOÀN TẤT ĐỒNG BỘ {0} BẢNG LED THÀNH CÔNG!", targetBoards.Count)
                        : "Một số bảng LED không thể kết nối. Vui lòng kiểm tra nguồn card LED!";
                    lock (syncLock) {
                        syncSuccess = allSuccess;
                        syncMessage = finalMsg;
                        syncRunning = false;
                    }
                }
            });
        }

        private static void SendJsonResult(NetworkStream stream, bool success, string message, int code, string[] logs) {
            StringBuilder sb = new StringBuilder();
            sb.Append("{");
            sb.Append("\"success\":").Append(success ? "true" : "false").Append(",");
            sb.Append("\"code\":").Append(code).Append(",");
            sb.Append("\"message\":\"").Append(EscapeJson(message)).Append("\",");
            sb.Append("\"logs\":[");
            if (logs != null) {
                for (int i = 0; i < logs.Length; i++) {
                    if (i > 0) sb.Append(",");
                    sb.Append("\"").Append(EscapeJson(logs[i])).Append("\"");
                }
            }
            sb.Append("]}");

            byte[] b = Encoding.UTF8.GetBytes(sb.ToString());
            SendHttpResponse(stream, 200, "OK", "application/json; charset=utf-8", b);
        }

        private static string GetJsonValue(string json, string key) {
            try {
                string pattern = "\"" + key + "\"";
                int idx = json.IndexOf(pattern, StringComparison.OrdinalIgnoreCase);
                if (idx < 0) return "";
                int colon = json.IndexOf(':', idx + pattern.Length);
                if (colon < 0) return "";
                int valStart = colon + 1;
                while (valStart < json.Length && char.IsWhiteSpace(json[valStart])) valStart++;
                if (valStart >= json.Length) return "";

                if (json[valStart] == '"') {
                    int valEnd = json.IndexOf('"', valStart + 1);
                    if (valEnd > valStart) return json.Substring(valStart + 1, valEnd - valStart - 1);
                } else {
                    int valEnd = valStart;
                    while (valEnd < json.Length && json[valEnd] != ',' && json[valEnd] != '}' && !char.IsWhiteSpace(json[valEnd])) valEnd++;
                    return json.Substring(valStart, valEnd - valStart);
                }
            } catch {}
            return "";
        }

        private static string EscapeJson(string s) {
            if (string.IsNullOrEmpty(s)) return "";
            return s.Replace("\\", "\\\\").Replace("\"", "\\\"").Replace("\r", "").Replace("\n", "\\n");
        }

        private static int GetColorValue(string colorName) {
            switch (colorName.ToLower()) {
                case "red": return Hd_GetColor(255, 0, 0);
                case "green": return Hd_GetColor(0, 255, 0);
                case "yellow": return Hd_GetColor(255, 255, 0);
                case "blue": return Hd_GetColor(0, 0, 255);
                case "cyan": return Hd_GetColor(0, 255, 255);
                case "magenta": return Hd_GetColor(255, 0, 255);
                case "white": return Hd_GetColor(255, 255, 255);
                default: return Hd_GetColor(0, 255, 0);
            }
        }

        private static void ServeStaticFile(NetworkStream stream, string rawUrl) {
            string file = "index.html";
            if (rawUrl != "/" && !string.IsNullOrEmpty(rawUrl)) {
                file = rawUrl.TrimStart('/').Split('?')[0];
            }
            string fullPath = Path.Combine(appDir, file);

            // Ho tro hien thi anh HD2020: /hd_images/Colorfulwords/01.gif hoac /hd_images/Border/001.png
            if (file.StartsWith("hd_images/", StringComparison.OrdinalIgnoreCase)) {
                string subPath = file.Substring(10).Replace("/", "\\");
                string hdImgPath = Path.Combine(hdInstallDir, "images", subPath);
                if (File.Exists(hdImgPath)) {
                    fullPath = hdImgPath;
                }
            }

            if (!File.Exists(fullPath)) {
                SendHttpResponse(stream, 404, "Not Found", "text/plain", Encoding.UTF8.GetBytes("File not found"));
                return;
            }
            byte[] bytes = File.ReadAllBytes(fullPath);
            string mime = "text/plain";
            string lower = fullPath.ToLower();
            if (lower.EndsWith(".html")) mime = "text/html; charset=utf-8";
            else if (lower.EndsWith(".js")) mime = "application/javascript";
            else if (lower.EndsWith(".css")) mime = "text/css";
            else if (lower.EndsWith(".png")) mime = "image/png";
            else if (lower.EndsWith(".gif")) mime = "image/gif";
            else if (lower.EndsWith(".jpg") || lower.EndsWith(".jpeg")) mime = "image/jpeg";
            else if (lower.EndsWith(".svg")) mime = "image/svg+xml";
            SendHttpResponse(stream, 200, "OK", mime, bytes);
        }
    }
}
