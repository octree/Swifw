//
//  SSLocal.swift
//  Socket
//
//  Created by Octree on 2020/2/22.
//

import Foundation
import Socket

public struct Net {
    public struct Address {
        public var host: String
        public var port: Int
    }
}

public class SSLocal: SecureSocket {
    private var listenAddr: Net.Address
    private var remoteAddr: Net.Address
    private var listenSocket: Socket? = nil

    public init(password: [Byte], listenAddr: Net.Address, remoteAddr: Net.Address) {
        self.listenAddr = listenAddr
        self.remoteAddr = remoteAddr
        super.init(cipher: Cipher.create(encodePassword: password))
    }

    deinit {
        self.listenSocket?.close()
    }

    public func listen(didListen: (() -> Void)? = nil) {
//        let queue = DispatchQueue.global(qos: .userInteractive)
//        queue.async { [unowned self] in
//
//        }
        self._listen(didListen: didListen)
    }

    private func handle(socket: Socket) {
        let queue = DispatchQueue.global(qos: .default)
        do {
            let remote = try dialRemote()
            let group = DispatchGroup()
            group.enter()
            queue.async { [unowned self] in
                do {
                    try self.encodeCopy(dst: remote, src: socket)
                } catch {
                    Vulcan.default.error("Failed send local -> remote \(error)")
                }
                group.leave()
            }
            group.enter()
            queue.async { [unowned self] in
                do {
                    try self.decodeCopy(dst: socket, src: remote)
                } catch {
                    Vulcan.default.error("Failed send local -> remote \(error)")
                }
                group.leave()
            }

            group.notify(queue: .global(qos: .userInitiated)) {
                remote.close()
                socket.close()
                Vulcan.default.info("🍄 Finish & Close")
            }
        } catch {
            Vulcan.default.error("Failed to connect to remote server, \(error)")
        }
    }

    private func dialRemote() throws -> Socket {
        let remote = try Socket.create(family: .inet, type: .stream)
        try remote.connect(to: remoteAddr.host, port: Int32(remoteAddr.port))
        return remote
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
            Vulcan.default.info("Local Did Listen, \(socket.socketfd)")
            while true {
                do {
                    let newSocket = try socket.acceptClientConnection()
                    Vulcan.default.info("Accepted connection from: \(newSocket.remoteHostname) on port \(newSocket.remotePort)")
                    Vulcan.default.info("Socket Signature: \(String(describing: newSocket.signature?.description))")
                    self.handle(socket: newSocket)
                } catch {
                    socket.close()
                    Vulcan.default.error("Failed to  accept connection, \(error)")
                }
            }
        } catch {
            Vulcan.default.error("Failed to listen, \(error)")
        }
    }
}
