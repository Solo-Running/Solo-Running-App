//
//  Constants.swift
//  Solo
//
//  Created by William Kim on 10/13/24.
//

import Foundation
import SwiftUI

enum DeleteStatus {
    case initial
    case deleting
    case success
    case failure
}

let BLUE = Color(.systemBlue)
let LIGHT_BLUE = Color(hex: 0x83B6FF)
let NEON = Color(hex: 0xD4D412)

let LIGHT_GREEN = Color(hex: 0x81D32A)
let DARK_GREEN = Color(hex: 0x4B7A09)
let DARK_GREY = Color(hex: 0x1E1E1E)
let LIGHT_GREY = Color(hex: 0x303030)
let BAR_GREY = Color(hex: 0x303030)
let RED = Color(hex: 0xED3023)

let TEXT_LIGHT_GREY = Color(hex: 0x868686)
let TEXT_LIGHT_GREEN = Color(hex: 0xC2FF6D)
let TEXT_DARK_NEON = Color(hex: 0xAC8A00)
let TEXT_LIGHT_RED = Color(hex: 0xFAB2B2)


let MAP_SNAPSHOT_ICON_SIZE = 16
let RUN_LIMIT = 12
let PIN_LIMIT = 8


// Configures the gradient appearance underneath the average pace graph
var GREEN_GRADIENT: LinearGradient {
    LinearGradient(
        gradient: Gradient(
            colors: [
                LIGHT_GREEN.opacity(0.8),
                LIGHT_GREEN.opacity(0.01),
            ]
        ),
        startPoint: .top,
        endPoint: .bottom
    )
}
