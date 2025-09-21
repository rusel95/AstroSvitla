//
//  Item.swift
//  AstroSvitla
//
//  Created by Ruslan Popesku on 21.09.2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
