//
//  Loggers.swift
//  LydiaBox
//
//  Created by Octree on 2019/6/20.
//  Copyright © 2019 Octree. All rights reserved.
//

import Foundation

public enum Loggers {
    struct NopLogger: Logging {
        func log(message: Vulcan.Message, level: Vulcan.Level, metadata: Vulcan.Metadata) {
            // do noting
        }
    }
    
    struct FilterLogger: Logging {
        public let level: Vulcan.Level
        public let positiveLogger: Logging
        public let negativeLogger: Logging
        
        func log(message: Vulcan.Message, level: Vulcan.Level, metadata: Vulcan.Metadata) {
            if self.level == level {
                positiveLogger.log(message: message, level: level, metadata: metadata)
            } else {
                negativeLogger.log(message: message, level: level, metadata: metadata)
            }
        }
    }
    
    struct IgnoringLogger: Logging {
        public let level: Vulcan.Level
        public let positiveLogger: Logging
        public let negativeLogger: Logging
        
        func log(message: Vulcan.Message, level: Vulcan.Level, metadata: Vulcan.Metadata) {
            if self.level >= level {
                positiveLogger.log(message: message, level: level, metadata: metadata)
            } else {
                negativeLogger.log(message: message, level: level, metadata: metadata)
            }
        }
    }
    
    struct SequenceLogger: Logging {
        public let loggers: [Logging]
        
        func log(message: Vulcan.Message, level: Vulcan.Level, metadata: Vulcan.Metadata) {
            loggers.forEach {
                $0.log(message: message, level: level, metadata: metadata)
            }
        }
    }
    
    struct FormatterLogger: Logging {
        public let formatter: Formatting
        public let logger: Logging
        
        func log(message: Vulcan.Message, level: Vulcan.Level, metadata: Vulcan.Metadata) {
            let message = formatter.format(message: message, level: level, metadata: metadata)
            logger.log(message: message, level: level, metadata: metadata)
        }
    }
    
    struct ConsoleLogger: Logging {
        func log(message: Vulcan.Message, level: Vulcan.Level, metadata: Vulcan.Metadata) {
            print(message)
        }
    }
    
    static var nop: Logging = Loggers.NopLogger()
}

public extension Logging {
    func filter(level: Vulcan.Level) -> Logging {
        return Loggers.FilterLogger(level: level, positiveLogger: self, negativeLogger: Loggers.nop)
    }
    
    func ignore(level: Vulcan.Level) -> Logging {
        return Loggers.IgnoringLogger(level: level, positiveLogger: self, negativeLogger: Loggers.nop)
    }
    
    static func sequence(loggers: [Logging]) -> Logging {
        return Loggers.SequenceLogger(loggers: loggers)
    }
    
    func format(_ formatter: Formatting) -> Logging {
        return Loggers.FormatterLogger(formatter: formatter, logger: self)
    }
}
