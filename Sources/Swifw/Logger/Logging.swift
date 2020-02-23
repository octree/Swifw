//
//  Logging.swift
//  LydiaBox
//
//  Created by Octree on 2019/6/20.
//  Copyright © 2019 Octree. All rights reserved.
//

import Foundation

public protocol Logging {
    func log(message: Vulcan.Message, level: Vulcan.Level, metadata: Vulcan.Metadata)
}
