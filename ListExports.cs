using System;
using System.IO;
using System.Text.RegularExpressions;

class ListExports {
    static void Main() {
        byte[] b = File.ReadAllBytes(@"C:\Program Files (x86)\HD2020\HDSDK.dll");
        string s = System.Text.Encoding.ASCII.GetString(b);
        MatchCollection mc = Regex.Matches(s, @"Hd_[A-Za-z0-9_]+");
        var list = new System.Collections.Generic.HashSet<string>();
        foreach (Match m in mc) {
            if (list.Add(m.Value)) {
                Console.WriteLine(m.Value);
            }
        }
    }
}
