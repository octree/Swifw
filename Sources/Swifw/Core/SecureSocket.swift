//
//  SecureSocket.swift
//  Socket
//
//  Created by Octree on 2020/2/22.
//

import Foundation
import Socket

public class SecureSocket {
    private let cipher: Cipher
    private static let bufferSize = 4096

    public init(cipher: Cipher) {
        self.cipher = cipher
    }

    public func decodeRead(socket: Socket) throws -> Data {
        var readData = Data(capacity: SecureSocket.bufferSize)
        let bytesRead = try socket.read(into: &readData)
        return cipher.decode(data: readData.subdata(in: 0..<bytesRead))
    }

    public func encodeWrite(data: Data, socket: Socket) throws {
        try socket.write(from: cipher.encode(data: data))
    }

    public func encodeCopy(dst: Socket, src: Socket) throws {
        var readData = Data(capacity: SecureSocket.bufferSize)
        while true {
            try src.setReadTimeout(value: 1000)
            let bytesRead = try src.read(into: &readData)
            if bytesRead == 0 {
                return
            }
            try encodeWrite(data: readData.subdata(in: 0..<bytesRead), socket: dst)
            readData.count = 0
            Vulcan.default.debug("💔 decode copy, \(dst.socketfd), \(src.socketfd)")
        }
    }

    public func decodeCopy(dst: Socket, src: Socket) throws {
        while true {
            try src.setReadTimeout(value: 1000)
            let data = try decodeRead(socket: src)
            if data.count == 0 {
                return
            }
            try dst.write(from: data)
            Vulcan.default.debug("💔 decode copy, \(dst.socketfd), \(src.socketfd)")
        }
    }
}

