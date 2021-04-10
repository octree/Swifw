//
//  SSServer.swift
//  Socket
//
//  Created by Octree on 2020/2/22.
//

import Foundation
import Socket

public class SSServer: SecureSocket {
    private var listenAddr: Net.Address
    private var listenSocket: Socket? = nil

    public init(password: [Byte], listenAddr: Net.Address) {
        self.listenAddr = listenAddr
        super.init(cipher: Cipher.create(encodePassword: password))
    }

    public func listen(didListen: (() -> Void)? = nil) {
        self._listen(didListen: didListen)
    }

    /*
    Handle the connection from LsLocal.
     */
    private func handle(socket: Socket) {
        Vulcan.default.info("😅 Handle")
        let queue = DispatchQueue.global(qos: .userInteractive)
        queue.async { [unowned self] in
            do {
                let buf = [Byte](try self.decodeRead(socket: socket))
                let byteLength = buf.count
                let portData = Data(buf[byteLength - 2 ..< byteLength])
                let port = UInt16(bigEndian: portData.withUnsafeBytes { $0.pointee })
                var host: String?
                var remote: Socket?
                switch buf[3] {
                case 0x1:
                    var dIP = buf[4...4+4]
                    let length = Int(INET_ADDRSTRLEN) + 2
                    var buffer = [CChar](repeating: 0, count: length)
                    let hostCString = inet_ntop(AF_INET, &dIP, &buffer, socklen_t(length))
                    host = String(cString: hostCString!)
                    remote = try Socket.create(family: .inet, type: .stream)
                case 0x3:
                    let nameData = Data(buf[5..<byteLength - 2])
                    host = String(data: nameData, encoding: .utf8)
                    remote = try Socket.create(type: .stream)
                case 0x4:
                    var dIP = buf[4..<4+16]
                    let length = Int(INET6_ADDRSTRLEN) + 2
                    var buffer = [CChar](repeating: 0, count: length)
                    let hostCString = inet_ntop(AF_INET6, &dIP, &buffer, socklen_t(length))
                    host = String(cString: hostCString!)
                    remote = try Socket.create(family: .inet6, type: .stream)
                default:
                    socket.close()
                    return
                }
                guard let remoteConn = remote, let hostName = host else {
                    socket.close()
                    return
                }
                Vulcan.default.info("🌏 Host: \(hostName) port: \(port)")
                try remoteConn.connect(to: hostName, port: Int32(port))
                try socket.write(from: Data([UInt8(1)]))
                let group = DispatchGroup()
                group.enter()
                DispatchQueue.global().async { [unowned self] in
                    do {
                        try self.decodeCopy(dst: remoteConn, src: socket)
                    } catch {
                        Vulcan.default.error("Failed send local -> dst \(error)")
                    }
                    group.leave()
                }
                group.enter()
                DispatchQueue.global().async { [unowned self] in
                    do {
                        try self.encodeCopy(dst: socket, src: remoteConn)
                    } catch {
                        Vulcan.default.error("Failed send dst -> local \(error)")
                    }
                    group.leave()
                }

                group.notify(queue: .global(qos: .userInteractive)) {
                    remoteConn.close()
                    socket.close()
                }
            } catch {
                socket.close()
                Vulcan.default.error("Error Occurred when receive from local, \(error)")
            }
        }
    }

    private func _listen(didListen: (() -> Void)? = nil) {
        do {
            listenSocket = try Socket.create(family: .inet, type: .stream)
            guard let socket = listenSocket else {
                Vulcan.default.error("Unable to unwrap socket...")
                return
            }
            try socket.listen(on: self.listenAddr.port)
            didListen?()
            Vulcan.default.info("Server Did Listen on :\(listenAddr.port), \(socket.socketfd)")
            while true {
                let newSocket = try socket.acceptClientConnection()
                Vulcan.default.info("Accepted connection from: \(newSocket.remoteHostname) on port \(newSocket.remotePort)")
                Vulcan.default.info("Socket Signature: \(String(describing: newSocket.signature?.description))")
                self.handle(socket: newSocket)
            }
        } catch {
            Vulcan.default.error("Failed to start listen, \(error)")
        }
    }
}
