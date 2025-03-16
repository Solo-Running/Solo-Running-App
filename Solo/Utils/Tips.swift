//
//  Tips.swift
//  Solo
//
//  Created by William Kim on 3/9/25.
//

import Foundation
import TipKit
import SwiftUI

struct DashboardChartTip: Tip {
    var title: Text {
        Text("Weekly Data")
    }
    
    var message: Text? {
        Text("Swipe horizontally to see your steps and time over the week")
    }
    
    var image: Image? {
        Image(systemName: "hand.draw")
    }
}
