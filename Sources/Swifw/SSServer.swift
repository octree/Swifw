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
        let queue = DispatchQueue.global(qos: .default)
        queue.async { [unowned self] in
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
            do {
                let bytes = [Byte](try self.decodeRead(socket: socket))
                if bytes.count == 0 || bytes[0] != 0x5 {
                    socket.close()
                    return
                }
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
                let responseHead: [Byte] = [0x5, 0x00]
                try self.encodeWrite(data: Data(responseHead), socket: socket)
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
                let buf = [Byte](try self.decodeRead(socket: socket))
                if buf.count < 7 {
                    socket.close()
                    return
                }

                if buf[1] != 0x01 {
                    socket.close()
                    return
                }
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
                let infoData = Data([Byte(0x05), 0x00, 0x00, 0x01, 0x00, 0x00,
                0x00, 0x00, 0x00, 0x00])
                try self.encodeWrite(data: infoData, socket: socket)
                let group = DispatchGroup()
                group.enter()
                queue.async { [unowned self] in
                    do {
                        try self.decodeCopy(dst: remoteConn, src: socket)
                    } catch {
                        Vulcan.default.error("Failed send local -> dst \(error)")
                    }
                    group.leave()
                }
                group.enter()
                queue.async { [unowned self] in
                    do {
                        try self.encodeCopy(dst: socket, src: remoteConn)
                    } catch {
                        Vulcan.default.error("Failed send dst -> local \(error)")
                    }
                    group.leave()
                }

                group.notify(queue: .global(qos: .userInitiated)) {
                    remoteConn.close()
                    socket.close()
                    Vulcan.default.info("Finish & Close")
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
