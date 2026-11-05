using System;
using System.IO;
using System.Runtime.InteropServices;

namespace HuiduSend {
    class Program {
        [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        public static extern bool SetDllDirectory(string lpPathName);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern IntPtr LoadLibrary(string lpFileName);

        [DllImport("HDSDK.dll", CallingConvention = CallingConvention.Cdecl)]
        public static extern int Hd_CreateScreen(int nWidth, int nHeight, int nColor, int nGray, int nCardType, IntPtr pParams, int nReserved);

        [DllImport("HDSDK.dll", CallingConvention = CallingConvention.Cdecl)]
        public static extern int Hd_AddProgram(IntPtr pParams, int nPlayTime, int nPlayCount, IntPtr pWeek, int nWeekLen);

        [DllImport("HDSDK.dll", CallingConvention = CallingConvention.Cdecl)]
        public static extern int Hd_AddArea(int nProgramID, int nX, int nY, int nWidth, int nHeight, IntPtr pBorderImgPath, int nBorderEffect, int nBorderSpeed, IntPtr pExParamsBuf, int nBufSize);

        [DllImport("HDSDK.dll", CallingConvention = CallingConvention.Cdecl)]
        public static extern int Hd_AddSimpleTextAreaItem(int nAreaID, [MarshalAs(UnmanagedType.LPWStr)] string pText, int nTextColor, int nBackGroupColor, int nStyle, [MarshalAs(UnmanagedType.LPWStr)] string pFontName, int nFontHeight, int nShowEffect, int nShowSpeed, int nClearType, int nStayTime, IntPtr pExParamsBuf, int nBufSize);

        [DllImport("HDSDK.dll", CallingConvention = CallingConvention.Cdecl)]
        public static extern int Hd_GetColor(int r, int g, int b);

        [DllImport("HDSDK.dll", EntryPoint = "Hd_SendScreen", CallingConvention = CallingConvention.Cdecl)]
        public static extern int Hd_SendScreenW(int nSendType, [MarshalAs(UnmanagedType.LPWStr)] string pStrParams, [MarshalAs(UnmanagedType.LPWStr)] string pDeviceGUID, IntPtr pExParamsBuf, int nBufSize);

        [DllImport("HDSDK.dll", EntryPoint = "Hd_SendScreen", CallingConvention = CallingConvention.Cdecl)]
        public static extern int Hd_SendScreenA(int nSendType, [MarshalAs(UnmanagedType.LPStr)] string pStrParams, [MarshalAs(UnmanagedType.LPStr)] string pDeviceGUID, IntPtr pExParamsBuf, int nBufSize);

        [DllImport("HDSDK.dll", CallingConvention = CallingConvention.Cdecl)]
        public static extern int Hd_GetSDKLastError();

        static int Main(string[] args) {
            Console.OutputEncoding = System.Text.Encoding.UTF8;

            string text = args.Length > 0 ? args[0] : "phúc";
            string color = args.Length > 1 ? args[1].ToLower() : "red";
            int fontSize = args.Length > 2 ? int.Parse(args[2]) : 16;
            int effect = args.Length > 3 ? int.Parse(args[3]) : 0;
            string ip = args.Length > 4 ? args[4] : "192.168.4.1";
            string guid = args.Length > 5 ? args[5] : null;

            string hdDir = @"C:\Program Files (x86)\HD2020";
            if (!Directory.Exists(hdDir)) {
                Console.WriteLine("[ERROR] Khong tim thay thu muc: " + hdDir);
                return 1;
            }

            SetDllDirectory(hdDir);
            IntPtr hDll = LoadLibrary(Path.Combine(hdDir, "HDSDK.dll"));
            if (hDll == IntPtr.Zero) {
                Console.WriteLine("[ERROR] Khong the tai HDSDK.dll. Ma loi: " + Marshal.GetLastWin32Error());
                return 2;
            }

            int colorVal;
            switch (color) {
                case "green": colorVal = Hd_GetColor(0, 255, 0); break;
                case "blue": colorVal = Hd_GetColor(0, 0, 255); break;
                case "yellow": colorVal = Hd_GetColor(255, 255, 0); break;
                case "white": colorVal = Hd_GetColor(255, 255, 255); break;
                case "cyan": colorVal = Hd_GetColor(0, 255, 255); break;
                case "magenta": colorVal = Hd_GetColor(255, 0, 255); break;
                default: colorVal = Hd_GetColor(255, 0, 0); break;
            }

            Console.WriteLine("[INFO] Tao chuong trinh LED: '" + text + "' (Mau: " + color + ", Co: " + fontSize + ")");

            // 1. Create Screen: 64x32, color=2, gray=1, cardType=142
            int nScreen = Hd_CreateScreen(64, 32, 2, 1, 142, IntPtr.Zero, 0);
            if (nScreen != 0) {
                Console.WriteLine("[ERROR] Hd_CreateScreen that bai! Ma loi: " + Hd_GetSDKLastError());
                return 3;
            }

            // 2. Add Program
            int nProgID = Hd_AddProgram(IntPtr.Zero, 10, 1, IntPtr.Zero, 0);

            // 3. Add Area: 0, 0, 64, 32
            int nAreaID = Hd_AddArea(nProgID, 0, 0, 64, 32, IntPtr.Zero, 0, 0, IntPtr.Zero, 0);

            // 4. Add Text Item
            int nItem = Hd_AddSimpleTextAreaItem(nAreaID, text, colorVal, 0, 1, "Arial", fontSize, effect, 10, 0, 3, IntPtr.Zero, 0);

            // 5. Send Screen
            // Lan luot thu cac to hop goi ham:
            // Thu 1: Unicode khong GUID
            int res = Hd_SendScreenW(0, ip, null, IntPtr.Zero, 0);
            if (res == 0) { Console.WriteLine("[SUCCESS] Bang da hien thi chu '" + text + "'!"); return 0; }

            // Thu 2: Unicode co GUID
            if (!string.IsNullOrEmpty(guid)) {
                res = Hd_SendScreenW(0, ip, guid, IntPtr.Zero, 0);
                if (res == 0) { Console.WriteLine("[SUCCESS] Bang da hien thi chu '" + text + "' (GUID)!"); return 0; }
            }

            // Thu 3: ANSI khong GUID
            res = Hd_SendScreenA(0, ip, null, IntPtr.Zero, 0);
            if (res == 0) { Console.WriteLine("[SUCCESS] Bang da hien thi chu '" + text + "'!"); return 0; }

            // Thu 4: ANSI co GUID
            if (!string.IsNullOrEmpty(guid)) {
                res = Hd_SendScreenA(0, ip, guid, IntPtr.Zero, 0);
                if (res == 0) { Console.WriteLine("[SUCCESS] Bang da hien thi chu '" + text + "' (GUID)!"); return 0; }
            }

            int lastErr = Hd_GetSDKLastError();
            Console.WriteLine("[ERROR] Gui that bai toi " + ip + "! Ma loi: " + lastErr);
            return lastErr == 0 ? -1 : lastErr;
        }
    }
}
