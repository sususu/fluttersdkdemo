import Foundation
import zlib

// The watch requires STORE entries and the same GNSS trailer as the native SDK demo.
enum AgpsPackage {
    static let names = ["f1e1G7.pgl", "f1e1C7.pgl", "f1e1J7.pgl", "f1e1E7.pgl", "f1e1R7.pgl"]
    static func process(_ data: Data) throws -> (data: Data, start: Int64, end: Int64) {
        guard data.count >= 37, data.count <= 10_000_000,
              data[35] > 0, data[36] > 0 else {
            throw NSError(domain: "AGPS", code: 1, userInfo: [NSLocalizedDescriptionKey: "星历文件头无效"])
        }
        let gnss = data[31..<35].reduce(Int64(0)) { ($0 << 8) | Int64($1) }
        var start = gnss + 315_964_800 - 18
        if data[30] == 3 { start += 820_108_800 + 14 }
        if data[30] == 2 { start += 619_315_187 + 13 }
        let end = start + Int64(data[35]) * Int64(data[36]) * 3600
        guard start > 0, end <= Int64(UInt32.max) else {
            throw NSError(domain: "AGPS", code: 2, userInfo: [NSLocalizedDescriptionKey: "星历有效期无效"])
        }
        var out = data
        out.append(Data("AGPS".utf8))
        out.append(contentsOf: UInt32(start).leBytes)
        out.append(contentsOf: UInt32(end).leBytes)
        out.append(Data(count: 4))
        return (out, start, end)
    }

    static func buildStoreZip(entries: [(String, Data)]) throws -> Data {
        var central = Data()
        var local = Data()
        var offset: UInt32 = 0
        for (name, data) in entries {
            let nameData = Data(name.utf8)
            var localHeader = Data()
            localHeader.append(contentsOf: UInt32(0x04034b50).leBytes) // local file header signature
            localHeader.append(contentsOf: UInt16(20).leBytes)         // version needed
            localHeader.append(contentsOf: UInt16(0).leBytes)          // general purpose bit flag
            localHeader.append(contentsOf: UInt16(0).leBytes)          // compression method = store
            localHeader.append(contentsOf: UInt16(0).leBytes)          // last mod time
            localHeader.append(contentsOf: UInt16(0).leBytes)          // last mod date
            let crc = crc32(data)
            localHeader.append(contentsOf: crc.leBytes)
            localHeader.append(contentsOf: UInt32(data.count).leBytes) // compressed size
            localHeader.append(contentsOf: UInt32(data.count).leBytes) // uncompressed size
            localHeader.append(contentsOf: UInt16(nameData.count).leBytes)
            localHeader.append(contentsOf: UInt16(0).leBytes)          // extra field length
            localHeader.append(nameData)
            localHeader.append(data)
            local.append(localHeader)

            var ch = Data()
            ch.append(contentsOf: UInt32(0x02014b50).leBytes) // central directory header
            ch.append(contentsOf: UInt16(20).leBytes)
            ch.append(contentsOf: UInt16(20).leBytes)
            ch.append(contentsOf: UInt16(0).leBytes)
            ch.append(contentsOf: UInt16(0).leBytes)
            ch.append(contentsOf: UInt16(0).leBytes)
            ch.append(contentsOf: UInt16(0).leBytes)
            ch.append(contentsOf: crc.leBytes)
            ch.append(contentsOf: UInt32(data.count).leBytes)
            ch.append(contentsOf: UInt32(data.count).leBytes)
            ch.append(contentsOf: UInt16(nameData.count).leBytes)
            ch.append(contentsOf: UInt16(0).leBytes)
            ch.append(contentsOf: UInt16(0).leBytes)
            ch.append(contentsOf: UInt16(0).leBytes)
            ch.append(contentsOf: UInt16(0).leBytes)
            ch.append(contentsOf: UInt32(0).leBytes)
            ch.append(contentsOf: offset.leBytes)
            ch.append(nameData)
            central.append(ch)
            offset += UInt32(localHeader.count)
        }
        var end = Data()
        end.append(contentsOf: UInt32(0x06054b50).leBytes) // end of central directory
        end.append(contentsOf: UInt16(0).leBytes)
        end.append(contentsOf: UInt16(0).leBytes)
        end.append(contentsOf: UInt16(entries.count).leBytes)
        end.append(contentsOf: UInt16(entries.count).leBytes)
        end.append(contentsOf: UInt32(central.count).leBytes)
        end.append(contentsOf: UInt32(local.count).leBytes)
        end.append(contentsOf: UInt16(0).leBytes)
        return local + central + end
    }

    /// CRC-32 used in ZIP local / central headers (zlib).
    private static func crc32(_ data: Data) -> UInt32 {
        data.withUnsafeBytes { buf -> UInt32 in
            let ptr = buf.bindMemory(to: UInt8.self).baseAddress
            return UInt32(zlib.crc32(0, ptr, UInt32(data.count)))
        }
    }
}

private extension FixedWidthInteger {
    /// Little-endian raw bytes of `self` for ZIP header fields.
    var leBytes: [UInt8] {
        withUnsafeBytes(of: littleEndian) { Array($0) }
    }
}
