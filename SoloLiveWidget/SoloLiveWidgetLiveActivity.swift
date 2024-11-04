//
//  SoloLiveWidgetLiveActivity.swift
//  SoloLiveWidget
//
//  Created by William Kim on 10/18/24.
//

import ActivityKit
import WidgetKit
import SwiftUI

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

struct SoloLiveWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var secondsElapsed: Int
        var steps: Int
    }

    // Fixed non-changing properties about your activity go here!
    var timerName: String
}

struct SoloLiveWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        
        ActivityConfiguration(for: SoloLiveWidgetAttributes.self) { context in
            
            VStack(alignment: .leading){
                HStack(alignment: .center) {
                    
                    Image("SoloLogo")
                        .resizable()
                        .frame(width: 30, height: 15)
                    
                    Text("Running")
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(hex: 0xD4D412))
                    
                    Spacer()
                    
                    Text("\(context.state.steps) steps")
                        .foregroundStyle(Color(hex: 0xC2FF6D))
                }
                
                HStack {
                    Text("Elapsed Time")
                        .foregroundStyle(.white)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text(
                        Duration.seconds(context.state.secondsElapsed).formatted(
                           .time(pattern: .hourMinuteSecond(padHourToLength: 2, fractionalSecondsLength: 0))
                       )
                    )
                    .contentTransition(.numericText())
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12).fill(Color(hex: 0x1E1E1E))
                )

                
            }
            .padding()
            .activityBackgroundTint(Color(hex: 0x242424).opacity(0.8))
            
            .activitySystemActionForegroundColor(.white)
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
        SoloLiveWidgetAttributes.ContentState(secondsElapsed: 0, steps: 0 )
     }
     
     fileprivate static var starEyes: SoloLiveWidgetAttributes.ContentState {
         SoloLiveWidgetAttributes.ContentState(secondsElapsed: 0, steps: 0)
     }
}

#Preview("Notification", as: .content, using: SoloLiveWidgetAttributes.preview) {
   SoloLiveWidgetLiveActivity()
} contentStates: {
    SoloLiveWidgetAttributes.ContentState.smiley
    SoloLiveWidgetAttributes.ContentState.starEyes
}
