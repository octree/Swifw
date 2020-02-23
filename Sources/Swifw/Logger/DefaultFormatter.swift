//
//  DefaultFormatter.swift
//  LydiaBox
//
//  Created by Octree on 2019/6/20.
//  Copyright © 2019 Octree. All rights reserved.
//

import Foundation

public class DefaultFormatter: Vulcan.Formatter {
    public init(useTerminalColors: Bool) {
        super.init()
        if useTerminalColors {
            reset = "\u{001b}[0m"
            escape = "\u{001b}[38;5;"
            levelColor.verbose = "251m"     // silver
            levelColor.debug = "35m"        // green
            levelColor.info = "38m"         // blue
            levelColor.warning = "178m"     // yellow
            levelColor.error = "197m"       // red
        } else {
            levelColor.verbose = "💜 "     // silver
            levelColor.debug = "💚 "        // green
            levelColor.info = "💙 "         // blue
            levelColor.warning = "💛 "     // yellow
            levelColor.error = "❤️ "       // red
        }
    }
}

