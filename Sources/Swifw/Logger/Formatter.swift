//
//  Formatter.swift
//  LydiaBox
//
//  Created by Octree on 2019/6/20.
//  Copyright © 2019 Octree. All rights reserved.
//

import Foundation

public protocol Formatting {
    func format(message: Vulcan.Message, level: Vulcan.Level, metadata: Vulcan.Metadata) -> String
}

//  Format 语法
//  $D date format start
//  $d date format end
//  $L level
//  $M message
//  $T thread
//  $N name of file without suffix
//  $n name of file with suffix
//  $F function
//  $l  line
//  $C  color code ("" on default)
//  $X  add the context
//  $c reset
//  $I ignore
extension Vulcan {
    
    open class Formatter: Formatting {
        public struct LevelColor {
            public var verbose = ""     // silver
            public var debug = ""       // green
            public var info = ""        // blue
            public var warning = ""     // yellow
            public var error = ""       // red
        }
        
        open var format: String = "$DHH:mm ss.SSS$d $C$L$c $N.$F:$l - $M"
        open var levelColor = LevelColor()
        open var reset: String = ""
        open var escape: String = ""
        fileprivate let formatter = DateFormatter()
        
        public func format(message: Vulcan.Message, level: Vulcan.Level, metadata: Vulcan.Metadata) -> String {
            return _format(message: message, level: level, metadata: metadata)
        }
    }
}


extension Vulcan.Formatter.LevelColor {
    public func color(forLevel level: Vulcan.Level) -> String {
        switch level {
        case .verbose:
            return verbose
        case .debug:
            return debug
        case .info:
            return info
        case .warning:
            return warning
        case .error:
            return error
        }
    }
    
    public subscript(level: Vulcan.Level) -> String {
        return color(forLevel: level)
    }
}

// MARK: - Format

extension Vulcan.Formatter {
    private func _format(message: Vulcan.Message, level: Vulcan.Level, metadata: Vulcan.Metadata) -> String {
        var text = ""
        // Prepend a $I for 'ignore' or else the first character is interpreted as a format character
        // even if the format string did not start with a $.
        let phrases: [String] = ("$I" + format).components(separatedBy: "$")
        
        for phrase in phrases where !phrase.isEmpty {
            let (padding, offset) = parsePadding(phrase)
            let formatCharIndex = phrase.index(phrase.startIndex, offsetBy: offset)
            let formatChar = phrase[formatCharIndex]
            let rangeAfterFormatChar = phrase.index(formatCharIndex, offsetBy: 1)..<phrase.endIndex
            let remainingPhrase = phrase[rangeAfterFormatChar]
            
            switch formatChar {
            case "I":  // ignore
                text += remainingPhrase
            case "L":
                text += paddedString(level.description, padding) + remainingPhrase
            case "M":
                text += paddedString(message.description, padding) + remainingPhrase
            case "T":
                text += paddedString(metadata.thread, padding) + remainingPhrase
            case "N":
                // name of file without suffix
                text += paddedString(fileNameWithoutSuffix(metadata.file), padding) + remainingPhrase
            case "n":
                // name of file with suffix
                text += paddedString(fileNameOfFile(metadata.file), padding) + remainingPhrase
            case "F":
                text += paddedString(metadata.function, padding) + remainingPhrase
            case "l":
                text += paddedString(String(metadata.line), padding) + remainingPhrase
            case "D":
                text += paddedString(formatDate(String(remainingPhrase)), padding)
            case "d":
                text += remainingPhrase
            case "C":
                // color code ("" on default)
                text += escape + levelColor[level] + remainingPhrase
            case "c":
                text += reset + remainingPhrase
            case "X":
                if let cx = metadata.context {
                    text += paddedString(String(describing: cx).trimmingCharacters(in: .whitespacesAndNewlines), padding) + remainingPhrase
                } else {
                    text += paddedString("", padding) + remainingPhrase
                }
            default:
                text += phrase
            }
        }
        // right trim only
        return text.replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression)
    }
    
    /// returns (padding length value, offset in string after padding info)
    private func parsePadding(_ text: String) -> (Int, Int) {
        // look for digits followed by a alpha character
        var s: String!
        var sign: Int = 1
        if text.first == "-" {
            sign = -1
            s = String(text.suffix(from: text.index(text.startIndex, offsetBy: 1)))
        } else {
            s = text
        }
        let numStr = s.prefix { $0 >= "0" && $0 <= "9" }
        if let num = Int(String(numStr)) {
            return (sign * num, (sign == -1 ? 1 : 0) + numStr.count)
        } else {
            return (0, 0)
        }
    }
    
    private func paddedString(_ text: String, _ toLength: Int, truncating: Bool = false) -> String {
        if toLength > 0 {
            // Pad to the left of the string
            if text.count > toLength {
                // Hm... better to use suffix or prefix?
                return truncating ? String(text.suffix(toLength)) : text
            } else {
                return "".padding(toLength: toLength - text.count, withPad: " ", startingAt: 0) + text
            }
        } else if toLength < 0 {
            // Pad to the right of the string
            let maxLength = truncating ? -toLength : max(-toLength, text.count)
            return text.padding(toLength: maxLength, withPad: " ", startingAt: 0)
        } else {
            return text
        }
    }
    
    /// returns the filename of a path
    func fileNameOfFile(_ file: String) -> String {
        let fileParts = file.components(separatedBy: "/")
        if let lastPart = fileParts.last {
            return lastPart
        }
        return ""
    }
    
    /// returns the filename without suffix (= file ending) of a path
    func fileNameWithoutSuffix(_ file: String) -> String {
        let fileName = fileNameOfFile(file)
        if !fileName.isEmpty {
            let fileNameParts = fileName.components(separatedBy: ".")
            if let firstPart = fileNameParts.first {
                return firstPart
            }
        }
        return ""
    }
    
    /// returns a formatted date string
    /// optionally in a given abbreviated timezone like "UTC"
    func formatDate(_ dateFormat: String) -> String {
        formatter.dateFormat = dateFormat
        let dateStr = formatter.string(from: Date())
        return dateStr
    }
}
