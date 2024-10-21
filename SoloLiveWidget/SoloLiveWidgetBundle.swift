//
//  SoloLiveWidgetBundle.swift
//  SoloLiveWidget
//
//  Created by William Kim on 10/18/24.
//

import WidgetKit
import SwiftUI

@main
struct SoloLiveWidgetBundle: WidgetBundle {
    var body: some Widget {
        SoloLiveWidget()
        SoloLiveWidgetLiveActivity()
    }
}
