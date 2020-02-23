//
//  Password.swift
//  Swifw
//
//  Created by Octree on 2020/2/22.
//

import Foundation

public struct Password {
    public enum InvalidError: Error {
        case invalid
    }

    public static let length = 256
    private static let identityPwd: [Byte] = [Byte](0...255)

    public static func validate(password: [Byte]) -> Bool {
        return password.count == length && Set(password).count == password.count
    }

    public static func loads(password: String) throws -> [Byte] {
        guard let data = Data(base64Encoded: password) else {
            throw InvalidError.invalid
        }
        return [Byte](data)
    }

    public static func dumps(password: [Byte]) throws -> String {
        guard validate(password: password) else {
            throw InvalidError.invalid
        }
        return Data(password).base64EncodedString()
    }

    public static func random() -> [Byte] {
        return identityPwd.shuffled()
    }
}
