//
//  Cipher.swift
//  Swifw
//
//  Created by Octree on 2020/2/22.
//

import Foundation


/// Cipher class is for the encipherment of data flow.
/// One octet is in the range 0 ~ 255 (2 ^ 8).
/// To do encryption, it just maps one byte to another one.
/// Example:
///     encodePassword
///     | index | 0x00 | 0x01 | 0x02 | 0x03 | ... | 0xff | || 0x02ff0a04
///     | ----- | ---- | ---- | ---- | ---- | --- | ---- | ||
///     | value | 0x01 | 0x02 | 0x03 | 0x04 | ... | 0x00 | \/ 0x03000b05
///     decodePassword
///     | index | 0x00 | 0x01 | 0x02 | 0x03 | 0x04 | ... | || 0x03000b05
///     | ----- | ---- | ---- | ---- | ---- | ---- | --- | ||
///     | value | 0xff | 0x00 | 0x01 | 0x02 | 0x03 | ... | \/ 0x02ff0a04
/// It just shifts one step to make a simply encryption, encode and decode.

public typealias Byte = UInt8

public struct Cipher {
    public let encodePassword: [Byte]
    public let decodePassword: [Byte]
}

public extension Cipher {
    func encode(bytes: [Byte]) -> [Byte] {
        return bytes.map { self.encodePassword[Int($0)] }
    }

    func decode(bytes: [Byte]) -> [Byte] {
        return bytes.map { self.decodePassword[Int($0)] }
    }

    func encode(data: Data) -> Data {
        return Data(encode(bytes: [Byte](data)))
    }

    func decode(data: Data) -> Data {
        return Data(decode(bytes: [Byte](data)))
    }
}

public extension Cipher {
    static func create(encodePassword: [Byte]) -> Cipher {
        var decodePassword = encodePassword
        for (idx, val) in encodePassword.enumerated() {
            decodePassword[Int(val)] = Byte(idx)
        }
        return Cipher(encodePassword: encodePassword,
                      decodePassword: decodePassword)
    }
}
