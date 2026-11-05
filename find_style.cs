using System;
using System.IO;
using System.Runtime.InteropServices;

class Program {
    [DllImport("kernel32.dll", SetLastError = true)]
    static extern bool SetDllDirectory(string path);
    [DllImport("kernel32.dll", SetLastError = true)]
    static extern IntPtr LoadLibrary(string path);
    [DllImport("kernel32.dll", SetLastError = true)]
    static extern IntPtr GetProcAddress(IntPtr hModule, string procName);

    static void Main() {
        SetDllDirectory(@"C:\Program Files (x86)\HD2020");
        IntPtr hMod = LoadLibrary(@"C:\Program Files (x86)\HD2020\HDSDK.dll");
        IntPtr pFunc = GetProcAddress(hMod, "Hd_AddSimpleTextAreaItem");

        // Dump bytes from offset 0 to 500
        byte[] code = new byte[600];
        Marshal.Copy(pFunc, code, 0, 600);

        // Look for [ebp+18h] which is 8B 45 18 or 8B 4D 18 or 8B 55 18
        for (int i = 0; i < code.Length - 3; i++) {
            if (code[i] == 0x8B && (code[i+1] == 0x45 || code[i+1] == 0x4D || code[i+1] == 0x55) && code[i+2] == 0x18) {
                Console.WriteLine("Found arg5 (nStyle) at offset {0}: {1:X2} {2:X2} {3:X2} {4:X2} {5:X2}", 
                    i, code[i], code[i+1], code[i+2], code[i+3], code[i+4]);
            }
        }
    }
}
