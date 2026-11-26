import Foundation
import MachO

/// Минимальная работа с Mach-O: проверка шифрования и добавление LC_LOAD_DYLIB.
/// Поддерживает thin arm64 и fat-бинарники (каждый срез обрабатывается отдельно).
enum MachO {
    static func isEncrypted(_ url: URL) throws -> Bool {
        let data = try Data(contentsOf: url, options: .mappedIfSafe)
        var encrypted = false
        try forEachSlice(data) { off in
            try forEachCommand(data, sliceOffset: off) { cmd, at in
                if cmd == LC_ENCRYPTION_INFO_64 || cmd == LC_ENCRYPTION_INFO {
                    let id: UInt32 = data.read(at + 16)
                    if id != 0 { encrypted = true }
                }
            }
        }
        return encrypted
    }

    static func insertLoadDylib(at url: URL, path: String) throws {
        var data = try Data(contentsOf: url)
        var slices: [Int] = []
        try forEachSlice(data) { slices.append($0) }
        for off in slices { try insert(into: &data, sliceOffset: off, path: path) }
        try data.write(to: url, options: .atomic)
    }

    // MARK: - internals

    private static func insert(into data: inout Data, sliceOffset off: Int, path: String) throws {
        let magic: UInt32 = data.read(off)
        guard magic == MH_MAGIC_64 else { throw PatchError("Поддерживаются только 64-битные срезы") }
        let ncmds: UInt32 = data.read(off + 16)
        let sizeofcmds: UInt32 = data.read(off + 20)
        let header = MemoryLayout<mach_header_64>.size

        // уже вставлено?
        var already = false
        var firstSection = Int.max
        try forEachCommand(data, sliceOffset: off) { cmd, at in
            if cmd == LC_LOAD_DYLIB || cmd == LC_LOAD_WEAK_DYLIB {
                let nameOff: UInt32 = data.read(at + 8)
                if data.cString(at: at + Int(nameOff)) == path { already = true }
            }
            if cmd == LC_SEGMENT_64 {
                let nsects: UInt32 = data.read(at + 64)
                for i in 0..<Int(nsects) {
                    let s = at + 72 + i * 80
                    let fileoff: UInt32 = data.read(s + 48)
                    let size: UInt64 = data.read(s + 40)
                    if fileoff > 0 && size > 0 { firstSection = min(firstSection, Int(fileoff)) }
                }
            }
        }
        if already { return }

        let nameBytes = Array(path.utf8) + [0]
        let cmdsize = (24 + nameBytes.count + 7) & ~7
        let insertAt = off + header + Int(sizeofcmds)
        guard insertAt + cmdsize <= off + firstSection else {
            throw PatchError("Нет места под новую load-команду")
        }
        var cmd = [UInt8](repeating: 0, count: cmdsize)
        cmd.write(UInt32(LC_LOAD_WEAK_DYLIB), at: 0)   // weak: если dylib нет, TikTok всё равно запустится
        cmd.write(UInt32(cmdsize), at: 4)
        cmd.write(UInt32(24), at: 8)                    // name offset
        cmd.write(UInt32(2), at: 12)                    // timestamp
        cmd.write(UInt32(0x10000), at: 16)              // current_version 1.0.0
        cmd.write(UInt32(0x10000), at: 20)              // compat_version
        cmd.replaceSubrange(24..<(24 + nameBytes.count), with: nameBytes)
        data.replaceSubrange(insertAt..<(insertAt + cmdsize), with: cmd)
        data.write(ncmds + 1, at: off + 16)
        data.write(sizeofcmds + UInt32(cmdsize), at: off + 20)
    }

    private static func forEachSlice(_ data: Data, _ body: (Int) throws -> Void) throws {
        let magic: UInt32 = data.read(0)
        if magic == FAT_CIGAM || magic == FAT_MAGIC {
            let n = UInt32(bigEndian: data.read(4))
            for i in 0..<Int(n) {
                let entry = 8 + i * 20
                let o = UInt32(bigEndian: data.read(entry + 8))
                try body(Int(o))
            }
        } else if magic == MH_MAGIC_64 {
            try body(0)
        } else {
            throw PatchError("Это не Mach-O файл")
        }
    }

    private static func forEachCommand(_ data: Data, sliceOffset off: Int, _ body: (UInt32, Int) throws -> Void) throws {
        let ncmds: UInt32 = data.read(off + 16)
        var at = off + MemoryLayout<mach_header_64>.size
        for _ in 0..<ncmds {
            let cmd: UInt32 = data.read(at)
            let size: UInt32 = data.read(at + 4)
            guard size >= 8 else { throw PatchError("Повреждённая load-команда") }
            try body(cmd, at)
            at += Int(size)
        }
    }
}

private extension Data {
    func read<T: FixedWidthInteger>(_ at: Int) -> T {
        var v: T = 0
        _ = Swift.withUnsafeMutableBytes(of: &v) { copyBytes(to: $0, from: at..<(at + MemoryLayout<T>.size)) }
        return T(littleEndian: v)
    }
    mutating func write<T: FixedWidthInteger>(_ v: T, at: Int) {
        Swift.withUnsafeBytes(of: v.littleEndian) { replaceSubrange(at..<(at + MemoryLayout<T>.size), with: $0) }
    }
    func cString(at: Int) -> String {
        var end = at
        while end < count && self[end] != 0 { end += 1 }
        return String(decoding: self[at..<end], as: UTF8.self)
    }
}

private extension Array where Element == UInt8 {
    mutating func write(_ v: UInt32, at: Int) {
        Swift.withUnsafeBytes(of: v.littleEndian) { replaceSubrange(at..<(at + 4), with: $0) }
    }
}
