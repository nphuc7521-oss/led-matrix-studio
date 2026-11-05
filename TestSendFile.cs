using System;
using System.IO;
using System.Runtime.InteropServices;

namespace HuiduTest {
    class Program {
        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern bool SetDllDirectory(string lpPathName);
        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern IntPtr LoadLibrary(string lpFileName);

        [DllImport("HDSDK.dll", EntryPoint = "Hd_SendScreenFromFile", CallingConvention = CallingConvention.Cdecl)]
        public static extern int Hd_SendScreenFromFileA(int nSendType, [MarshalAs(UnmanagedType.LPStr)] string pStrParams, [MarshalAs(UnmanagedType.LPStr)] string pDeviceGUID, [MarshalAs(UnmanagedType.LPStr)] string pFilePath, IntPtr pCallback, IntPtr pUser, int nReserved);

        [DllImport("HDSDK.dll", EntryPoint = "Hd_SendScreenFromFile", CallingConvention = CallingConvention.Cdecl)]
        public static extern int Hd_SendScreenFromFileW(int nSendType, [MarshalAs(UnmanagedType.LPWStr)] string pStrParams, [MarshalAs(UnmanagedType.LPWStr)] string pDeviceGUID, [MarshalAs(UnmanagedType.LPWStr)] string pFilePath, IntPtr pCallback, IntPtr pUser, int nReserved);

        [DllImport("HDSDK.dll", CallingConvention = CallingConvention.Cdecl)]
        public static extern int Hd_GetSDKLastError();

        static int Main(string[] args) {
            string hdDir = @"C:\Program Files (x86)\HD2020";
            SetDllDirectory(hdDir);
            LoadLibrary(Path.Combine(hdDir, "HDSDK.dll"));

            string xmlFile = @"C:\Users\PC\AppData\Roaming\Huidu\HD2020\program\2026_11_02_15_41_47_{358aed75-f820-4266-a325-819cee9ab0e1}.xml";
            Console.WriteLine("Testing Hd_SendScreenFromFile on: " + xmlFile);

            // Try A
            int rA = Hd_SendScreenFromFileA(0, "192.168.4.1", null, xmlFile, IntPtr.Zero, IntPtr.Zero, 0);
            Console.WriteLine("A result: " + rA + " (Err: " + Hd_GetSDKLastError() + ")");

            // Try W
            int rW = Hd_SendScreenFromFileW(0, "192.168.4.1", null, xmlFile, IntPtr.Zero, IntPtr.Zero, 0);
            Console.WriteLine("W result: " + rW + " (Err: " + Hd_GetSDKLastError() + ")");

            return 0;
        }
    }
}
