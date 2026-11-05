using System;
using System.IO;
using System.Text;
using System.Text.RegularExpressions;

class Program {
    static void Main() {
        string[] dlls = Directory.GetFiles(@"C:\Program Files (x86)\HD2020", "*.dll");
        foreach (string dll in dlls) {
            byte[] bytes = File.ReadAllBytes(dll);
            string s = Encoding.Unicode.GetString(bytes) + " " + Encoding.ASCII.GetString(bytes) + " " + Encoding.UTF8.GetString(bytes);
            if (s.Contains("Show immediately") || s.Contains("Move Left") || s.Contains("Pull upward")) {
                Console.WriteLine("Found in: " + Path.GetFileName(dll));
                var matches = Regex.Matches(s, @"[A-Za-z0-9 _-]{5,40}");
                int count = 0;
                foreach (Match m in matches) {
                    string v = m.Value;
                    if (v.Contains("Move") || v.Contains("Pull") || v.Contains("Show") || v.Contains("Twinkle") || v.Contains("Snow")) {
                        Console.WriteLine("  " + v);
                        if (++count > 25) break;
                    }
                }
            }
        }
    }
}
