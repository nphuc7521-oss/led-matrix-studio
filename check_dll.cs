using System;
using System.IO;
using System.Text;
using System.Text.RegularExpressions;

class Program {
    static void Main() {
        byte[] bytes = File.ReadAllBytes(@"C:\Program Files (x86)\HD2020\HDSDK.dll");
        string s = Encoding.ASCII.GetString(bytes);
        var matches = Regex.Matches(s, @"[A-Za-z0-9_]{4,50}");
        foreach (Match m in matches) {
            string v = m.Value;
            if (v.IndexOf("Effect", StringComparison.OrdinalIgnoreCase) >= 0 ||
                v.IndexOf("TextArea", StringComparison.OrdinalIgnoreCase) >= 0 ||
                v.IndexOf("Simple", StringComparison.OrdinalIgnoreCase) >= 0 ||
                v.IndexOf("AddArea", StringComparison.OrdinalIgnoreCase) >= 0 ||
                v.IndexOf("SendScreen", StringComparison.OrdinalIgnoreCase) >= 0) {
                Console.WriteLine(v);
            }
        }
    }
}
