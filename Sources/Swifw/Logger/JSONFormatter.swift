//
//  JSONFormatter.swift
//  LydiaBox
//
//  Created by Octree on 2019/6/20.
//  Copyright © 2019 Octree. All rights reserved.
//

import Foundation

//open class JSONFormatter: Logger.Formatter {
//    open override func format(message: Logger.Message, level: Logger.Level, metadata: Logger.Metadata) -> String {
//        var dict: [String: Any] = [
//            "timestamp": Date().timeIntervalSince1970,
//            "level": level.description,
//            "message": message.description,
//            "thread": metadata.thread,
//            "file": metadata.file,
//            "function": metadata.function,
//            "line": metadata.line
//        ]
//        if let cx = metadata.context {
//            dict["context"] = cx
//        }
//    }
//}
