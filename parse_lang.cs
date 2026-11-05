using System;
using System.Xml;

class Program {
    static void Main() {
        XmlDocument doc = new XmlDocument();
        doc.Load(@"C:\Program Files (x86)\HD2020\language\03_English.dll");
        foreach (XmlNode node in doc.SelectNodes("//Item")) {
            string name = node.Attributes["name"] != null ? node.Attributes["name"].Value : "";
            if (node.InnerText.Contains("immediately") || node.InnerText.Contains("Move") || node.InnerText.Contains("Pull") || node.InnerText.Contains("Snow") || node.InnerText.Contains("Twinkle")) {
                Console.WriteLine("{0} = {1}", name, node.InnerText);
            }
        }
    }
}
