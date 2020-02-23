//
//  Vulcan.swift
//  LydiaBox
//
//  Created by Octree on 2019/6/20.
//  Copyright © 2019 Octree. All rights reserved.
//

import Foundation

open class Vulcan {

    public static let `default` =  Vulcan(logger: Loggers.ConsoleLogger().format(DefaultFormatter(useTerminalColors: true)))

    open var logger: Logging
    public init(logger: Logging) {
        self.logger = logger
    }
}

public extension Vulcan {
    
    func log(_ message: Vulcan.Message, level: Vulcan.Level, context: Any? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        
        let metadata = Vulcan.Metadata(thread: getThreadName(),
                                       file: file,
                                       function: function,
                                       line: line,
                                       context: context)
        logger.log(message: message, level: level, metadata: metadata)
    }
    
    func verbose(_ message: Vulcan.Message, context: Any? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .verbose, context: context, file: file, function: function, line: line)
    }
    
    func debug(_ message: Vulcan.Message, context: Any? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, context: context, file: file, function: function, line: line)
    }
    
    func warning(_ message: Vulcan.Message, context: Any? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, context: context, file: file, function: function, line: line)
    }
    
    func info(_ message: Vulcan.Message, context: Any? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, context: context, file: file, function: function, line: line)
    }
    
    func error(_ message: Vulcan.Message, context: Any? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, context: context, file: file, function: function, line: line)
    }
    
    private func getThreadName() -> String {
        if Thread.isMainThread {
            return ""
        } else {
            let threadName = Thread.current.name
            if let threadName = threadName, !threadName.isEmpty {
                return threadName
            } else {
                return String(format: "%p", Thread.current)
            }
        }
    }
}

public extension Vulcan {
    
    typealias Message = String
    
    enum Level: CaseIterable {
        case verbose
        case debug
        case info
        case warning
        case error
    }
    
    struct Metadata {
        public var thread: String
        public var file: String
        public var function: String
        public var line: Int
        public var context: Any?
    }
}


extension Vulcan.Level: Comparable {
    public static func < (lhs: Vulcan.Level, rhs: Vulcan.Level) -> Bool {
        return lhs.natureIntegerValue < rhs.natureIntegerValue
    }
    
    internal var natureIntegerValue: Int {
        switch self {
        case .verbose:
            return 0
        case .debug:
            return 1
        case .info:
            return 2
        case .warning:
            return 3
        case .error:
            return 4
        }
    }
}

extension Vulcan.Level: CustomStringConvertible {
    public var description: String {
        switch self {
        case .verbose:
            return "VERBOSE"
        case .debug:
            return "DEBUG"
        case .info:
            return "INFO"
        case .warning:
            return "WARNING"
        case .error:
            return "ERROR"
        }
    }
}
