//
//  Constants.swift
//  Solo
//
//  Created by William Kim on 10/13/24.
//

import Foundation
import SwiftUI

let BLUE = Color(.blue)
let NEON = Color(hex: 0xD4D412)
let LIGHT_GREY = Color(hex: 0x1E1E1E)
let DARK_GREY = Color(hex: 0x242424)

let TEXT_LIGHT_GREY = Color(hex: 0x868686)
let RED = Color(hex: 0xED3023)



extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }
}
