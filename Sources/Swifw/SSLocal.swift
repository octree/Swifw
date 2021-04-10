//
//  SSLocal.swift
//  Socket
//
//  Created by Octree on 2020/2/22.
//

import Foundation
import Socket

extension Socket {
    func read() throws -> Data {
        var readData = Data(capacity: 1024)
        let bytesRead = try read(into: &readData)
        return readData.subdata(in: 0..<bytesRead)
    }
}

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
        let queue = DispatchQueue.global(qos: .userInteractive)
        queue.async { [unowned self] in
            do {
                /*
                SOCKS Protocol Version 5 https://www.ietf.org/rfc/rfc1928.txt
                The localConn connects to the dstServer, and sends a ver
                identifier/method selection message:
                            +----+----------+----------+
                            |VER | NMETHODS | METHODS  |
                            +----+----------+----------+
                            | 1  |    1     | 1 to 255 |
                            +----+----------+----------+
                The VER field is set to X'05' for this ver of the protocol.  The
                NMETHODS field contains the number of method identifier octets that
                appear in the METHODS field.
                */
                let bytes = [Byte](try socket.read())
                if bytes.count == 0 || bytes[0] != 0x5 {
                    Vulcan.default.info("🤪 NOT SOCKS5, \(bytes)")
                    socket.close()
                    return
                }
                Vulcan.default.info("🐇 IS SOCKS5, \(bytes)")

                /*
                The dstServer selects from one of the methods given in METHODS, and
                sends a METHOD selection message:
                            +----+--------+
                            |VER | METHOD |
                            +----+--------+
                            | 1  |   1    |
                            +----+--------+
                If the selected METHOD is X'FF', none of the methods listed by the
                client are acceptable, and the client MUST close the connection.

                The values currently defined for METHOD are:

                        o  X'00' NO AUTHENTICATION REQUIRED
                        o  X'01' GSSAPI
                        o  X'02' USERNAME/PASSWORD
                        o  X'03' to X'7F' IANA ASSIGNED
                        o  X'80' to X'FE' RESERVED FOR PRIVATE METHODS
                        o  X'FF' NO ACCEPTABLE METHODS

                The client and server then enter a method-specific sub-negotiation.
                */
                try socket.write(from: Data([UInt8(0x5), 0x00]))
                /*
                 The SOCKS request is formed as follows:
                     +----+-----+-------+------+----------+----------+
                     |VER | CMD |  RSV  | ATYP | DST.ADDR | DST.PORT |
                     +----+-----+-------+------+----------+----------+
                     | 1  |  1  | X'00' |  1   | Variable |    2     |
                     +----+-----+-------+------+----------+----------+
                 Where:

                   o  VER    protocol version: X'05'
                   o  CMD
                      o  CONNECT X'01'
                      o  BIND X'02'
                      o  UDP ASSOCIATE X'03'
                   o  RSV    RESERVED
                   o  ATYP   address type of following address
                      o  IP V4 address: X'01'
                      o  DOMAINNAME: X'03'
                      o  IP V6 address: X'04'
                   o  DST.ADDR       desired destination address
                   o  DST.PORT desired destination port in network octet
                      order
                 */
                let buf = [Byte](try socket.read())
                if buf.count < 7 {
                    Vulcan.default.error("🤪 LENGTH BELOWS 7")
                    socket.close()
                    return
                }

                Vulcan.default.info("🐇 LENGTH OK, \(buf)")
                if buf[1] != 0x01 {
                    Vulcan.default.error("🤪 METHOD NOT CONNECT")
                    socket.close()
                    return
                }
                Vulcan.default.info("🐇 METHOD OK")

                if buf[3] != 0x1 && buf[3] != 0x3 && buf[3] != 0x4 {
                    Vulcan.default.error("🤪 FAMILY NOT OK")
                    socket.close()
                    return
                }
                Vulcan.default.info("🤪 FAMILY OK")
                /*
                 The SOCKS request information is sent by the client as soon as it has
                 established a connection to the SOCKS server, and completed the
                 authentication negotiations.  The server evaluates the request, and
                 returns a reply formed as follows:

                         +----+-----+-------+------+----------+----------+
                         |VER | REP |  RSV  | ATYP | BND.ADDR | BND.PORT |
                         +----+-----+-------+------+----------+----------+
                         | 1  |  1  | X'00' |  1   | Variable |    2     |
                         +----+-----+-------+------+----------+----------+

                     Where:

                         o  VER    protocol version: X'05'
                         o  REP    Reply field:
                             o  X'00' succeeded
                             o  X'01' general SOCKS server failure
                             o  X'02' connection not allowed by ruleset
                             o  X'03' Network unreachable
                             o  X'04' Host unreachable
                             o  X'05' Connection refused
                             o  X'06' TTL expired
                             o  X'07' Command not supported
                             o  X'08' Address type not supported
                             o  X'09' to X'FF' unassigned
                         o  RSV    RESERVED
                         o  ATYP   address type of following address
                 */
                let remote = try self.dialRemote()
                try self.encodeWrite(data: Data(buf), socket: remote)
                _ = try remote.read()

                let infoData = Data([Byte(0x05), 0x00, 0x00, 0x01, 0x00, 0x00,
                0x00, 0x00, 0x00, 0x00])
                try socket.write(from: infoData)
                let group = DispatchGroup()
                group.enter()
                DispatchQueue.global().async { [unowned self] in
                    do {
                        try self.encodeCopy(dst: remote, src: socket)
                    } catch {
                        Vulcan.default.error("Failed send local -> remote \(error)")
                    }
                    group.leave()
                }
                group.enter()
                DispatchQueue.global().async { [unowned self] in
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
                }
            } catch {
                Vulcan.default.error("Failed to connect to remote server, \(error)")
            }
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
            Vulcan.default.info("Local Did Listen on :\(listenAddr.port), \(socket.socketfd)")
            while true {
                do {
                    let newSocket = try socket.acceptClientConnection()
                    Vulcan.default.info("Accepted connection from: \(newSocket.remoteHostname) on port \(newSocket.remotePort)")
                    Vulcan.default.info("Socket Signature: \(String(describing: newSocket.signature?.description))")
                    self.handle(socket: newSocket)
                } catch {
                    socket.close()
                    Vulcan.default.error("Failed to accept connection, \(error)")
                }
            }
        } catch {
            Vulcan.default.error("Failed to listen, \(error)")
        }
    }
}
