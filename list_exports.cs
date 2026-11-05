using System;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;

class Program {
    static void Main() {
        byte[] bytes = File.ReadAllBytes(@"C:\Program Files (x86)\HD2020\HDSDK.dll");
        int peOffset = BitConverter.ToInt32(bytes, 0x3C);
        int optHeaderOffset = peOffset + 4 + 20;
        int exportDirRva = BitConverter.ToInt32(bytes, optHeaderOffset + 96);
        
        // Find section containing exportDirRva
        int numSections = BitConverter.ToInt16(bytes, peOffset + 4 + 2);
        int sectionHeadersOffset = optHeaderOffset + BitConverter.ToInt16(bytes, peOffset + 4 + 16);

        int exportFileOffset = 0;
        for (int i = 0; i < numSections; i++) {
            int secOffset = sectionHeadersOffset + i * 40;
            int virtAddr = BitConverter.ToInt32(bytes, secOffset + 12);
            int rawSize = BitConverter.ToInt32(bytes, secOffset + 16);
            int rawAddr = BitConverter.ToInt32(bytes, secOffset + 20);
            if (exportDirRva >= virtAddr && exportDirRva < virtAddr + rawSize) {
                exportFileOffset = rawAddr + (exportDirRva - virtAddr);
                break;
            }
        }

        int numNames = BitConverter.ToInt32(bytes, exportFileOffset + 24);
        int namesRva = BitConverter.ToInt32(bytes, exportFileOffset + 32);

        int namesFileOffset = 0;
        for (int i = 0; i < numSections; i++) {
            int secOffset = sectionHeadersOffset + i * 40;
            int virtAddr = BitConverter.ToInt32(bytes, secOffset + 12);
            int rawSize = BitConverter.ToInt32(bytes, secOffset + 16);
            int rawAddr = BitConverter.ToInt32(bytes, secOffset + 20);
            if (namesRva >= virtAddr && namesRva < virtAddr + rawSize) {
                namesFileOffset = rawAddr + (namesRva - virtAddr);
                break;
            }
        }

        Console.WriteLine("Total exports: " + numNames);
        for (int i = 0; i < numNames; i++) {
            int nameRva = BitConverter.ToInt32(bytes, namesFileOffset + i * 4);
            int nameFileOffset = 0;
            for (int s = 0; s < numSections; s++) {
                int secOffset = sectionHeadersOffset + s * 40;
                int virtAddr = BitConverter.ToInt32(bytes, secOffset + 12);
                int rawSize = BitConverter.ToInt32(bytes, secOffset + 16);
                int rawAddr = BitConverter.ToInt32(bytes, secOffset + 20);
                if (nameRva >= virtAddr && nameRva < virtAddr + rawSize) {
                    nameFileOffset = rawAddr + (nameRva - virtAddr);
                    break;
                }
            }
            int end = nameFileOffset;
            while (bytes[end] != 0) end++;
            string name = Encoding.ASCII.GetString(bytes, nameFileOffset, end - nameFileOffset);
            Console.WriteLine(name);
        }
    }
}
