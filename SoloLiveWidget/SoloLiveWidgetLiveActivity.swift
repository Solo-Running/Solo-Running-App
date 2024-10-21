//
//  SoloLiveWidgetLiveActivity.swift
//  SoloLiveWidget
//
//  Created by William Kim on 10/18/24.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct SoloLiveWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var secondsElapsed: Int
    }

    // Fixed non-changing properties about your activity go here!
    var timerName: String
}

struct SoloLiveWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SoloLiveWidgetAttributes.self) { context in
            VStack {
                Text("Time Elapsed:")
                    .foregroundStyle(.black)
                Text("\(context.state.secondsElapsed) seconds")
                    .font(.largeTitle)
                    .foregroundStyle(.black)
                
            }
            .activitySystemActionForegroundColor(Color.black)
        } dynamicIsland: { context in
              // Create the presentations that appear in the Dynamic Island.
              DynamicIsland {
                  
                  DynamicIslandExpandedRegion(.leading) {
                     Image(systemName: "figure.walk.motion")
                          .foregroundStyle(.black)
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

extension SoloLiveWidgetAttributes {
    fileprivate static var preview: SoloLiveWidgetAttributes {
        SoloLiveWidgetAttributes(timerName: "timer")
    }
}

extension SoloLiveWidgetAttributes.ContentState {
    fileprivate static var smiley: SoloLiveWidgetAttributes.ContentState {
        SoloLiveWidgetAttributes.ContentState(secondsElapsed: 0)
     }
     
     fileprivate static var starEyes: SoloLiveWidgetAttributes.ContentState {
         SoloLiveWidgetAttributes.ContentState(secondsElapsed: 0)
     }
}

#Preview("Notification", as: .content, using: SoloLiveWidgetAttributes.preview) {
   SoloLiveWidgetLiveActivity()
} contentStates: {
    SoloLiveWidgetAttributes.ContentState.smiley
    SoloLiveWidgetAttributes.ContentState.starEyes
}
