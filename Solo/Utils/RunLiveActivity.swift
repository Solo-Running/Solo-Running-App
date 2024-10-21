//
//  RunLiveActivity.swift
//  Solo
//
//  Created by William Kim on 10/18/24.
//

import Foundation
import ActivityKit
import WidgetKit
import SwiftUI

struct RunLiveActivity: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var secondsElapsed: Int
    }

    var timerName: String
}




struct RunLiveActivityConfiguration: Widget {
    var body: some WidgetConfiguration {
          ActivityConfiguration(for: RunLiveActivity.self) { context in
              VStack {
                  Text("Time Elapsed:")
                  Text("\(context.state.secondsElapsed) seconds")
                      .font(.largeTitle)
              }
              .activityBackgroundTint(NEON)
              .activitySystemActionForegroundColor(Color.white)
          } dynamicIsland: { context in
                // Create the presentations that appear in the Dynamic Island.
                DynamicIsland {
                    
                    DynamicIslandExpandedRegion(.leading) {
                       Image(systemName: "figure.walk.motion")
                         .foregroundStyle(NEON)
                         .font(.title2)
                     }
                    
                      DynamicIslandExpandedRegion(.trailing) {
                        Label {
                            Text("\(context.state.secondsElapsed)")
                              .multilineTextAlignment(.trailing)
                              .frame(width: 50)
                              .monospacedDigit()
                        } icon: {
                            Image(systemName: "timer")
                                .foregroundColor(.indigo)
                        }
                        .font(.title2)
                      }
                } compactLeading: {
                    // Create the compact leading presentation.
                    Text(context.attributes.timerName)
                } compactTrailing: {
                    // Create the compact trailing presentation.
                    Text("\(context.state.secondsElapsed)")
                } minimal: {
                    Text("\(context.state.secondsElapsed)")
                }
            }
      }
}
