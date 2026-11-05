using System;
using System.Xml;

class Program {
    static void Main() {
        XmlDocument doc = new XmlDocument();
        doc.Load(@"C:\Program Files (x86)\HD2020\language\03_English.dll");
        foreach (XmlNode node in doc.SelectNodes("//Item")) {
            string name = node.Attributes["name"] != null ? node.Attributes["name"].Value : "";
            string val = node.InnerText;
            if (name.IndexOf("Effect", StringComparison.OrdinalIgnoreCase) >= 0 ||
                name.IndexOf("Show", StringComparison.OrdinalIgnoreCase) >= 0 ||
                name.IndexOf("Action", StringComparison.OrdinalIgnoreCase) >= 0) {
                Console.WriteLine("{0} = {1}", name, val);
            }
        }
    }
}
