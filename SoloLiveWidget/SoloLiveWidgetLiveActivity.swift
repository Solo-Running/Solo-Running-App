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
        var steps: Int
    }

    // Fixed non-changing properties about your activity go here!
    var startTime: Date
    var endTime: Date
}

func formattedSteps(_ steps: Int) -> String {
    if steps >= 1000000 {
        return "\(steps / 1000000)M"
    } else if steps >= 1000 {
        let formatted = Double(steps) / 1000
        return String(format: "%.2fk", formatted).replacingOccurrences(of: ".00", with: "")
    } else {
        return "\(steps)"
    }
}

struct SoloLiveWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        
        ActivityConfiguration(for: SoloLiveWidgetAttributes.self) { context in
            
            VStack(alignment: .leading){
                
                HStack(alignment: .center) {
                    
                    VStack(alignment: .leading) {
                        Text("\(formattedSteps(context.state.steps))")
                            .foregroundStyle(Color(hex: 0x81D32A))
                            .font(.largeTitle)
                            .fontWeight(.heavy)
                        
                        Text("Steps")
                            .foregroundStyle(Color(hex: 0x81D32A))
                            .font(.subheadline)
                            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                    }

                    
                    Spacer()

                    
                    Divider().frame(width: 2, height: 32).overlay(Color(hex: 0x868686))

                    
                    Spacer()
                    
                    VStack(alignment: .leading) {
                        
                        Text(timerInterval: context.attributes.startTime...context.attributes.endTime, countsDown: false, showsHours: true)
                            .foregroundStyle(Color(hex: 0x868686 ))
                            .font(.largeTitle)
                            .fontWeight(.heavy)
                            .monospacedDigit()
                        
//                        Text(
//                            Duration.seconds(context.state.secondsElapsed).formatted(
//                               .time(pattern: .hourMinuteSecond(padHourToLength: 2, fractionalSecondsLength: 0))
//                           )
//                        )
//                        .monospacedDigit()
//                        .contentTransition(.numericText())
//                        .foregroundStyle(Color(hex: 0x868686 ))
//                        .font(.largeTitle)
//                        .fontWeight(.heavy)
                        
                        Text("Time")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(Color(hex: 0x868686))
                        
                    }
                    .frame(maxWidth: 170)
                    
                }
                .frame(height: 64)
                             
            }
            .padding()
            .activityBackgroundTint(Color(hex: 0x1E1E1E))
//            .activityBackgroundTint(Color(hex: 0x242424).opacity(0.8))
            
            .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                    // Expanded Regions
                    DynamicIslandExpandedRegion(.leading) {
                        EmptyView() // No visible content
                    }
                    DynamicIslandExpandedRegion(.trailing) {
                        EmptyView() // No visible content
                    }
                    DynamicIslandExpandedRegion(.bottom) {
                        EmptyView() // No visible content
                    }
                } compactLeading: {
                    // Compact leading view content
                    Text("Compact")
                } compactTrailing: {
                    // Compact trailing view content
                    Text("View")
                } minimal: {
                    // Minimal view content
                    Text("Min")
                }
                .keylineTint(Color.clear)
              // Create the presentations that appear in the Dynamic Island.
//              DynamicIsland {
//                  
//                  DynamicIslandExpandedRegion(.leading) {
//                     Image(systemName: "figure.walk.motion")
//                          .foregroundStyle(.black)
//                       .font(.title2)
//                   }
//                  
//                    DynamicIslandExpandedRegion(.trailing) {
//                      Label {
//                          Text("\(context.state.secondsElapsed)")
//                            .multilineTextAlignment(.trailing)
//                            .frame(width: 50)
//                            .monospacedDigit()
//                      } icon: {
//                          Image(systemName: "timer")
//                              .foregroundColor(.indigo)
//                      }
//                      .font(.title2)
//                    }
//              } compactLeading: {
//                  // Create the compact leading presentation.
//                  Text(context.attributes.timerName)
//              } compactTrailing: {
//                  // Create the compact trailing presentation.
//                  Text("\(context.state.secondsElapsed)")
//              } minimal: {
//                  Text("\(context.state.secondsElapsed)")
//              }
          }
    }
}

extension SoloLiveWidgetAttributes {
    fileprivate static var preview: SoloLiveWidgetAttributes {
        SoloLiveWidgetAttributes(startTime: Date(), endTime: Date())
    }
}

extension SoloLiveWidgetAttributes.ContentState {
    fileprivate static var smiley: SoloLiveWidgetAttributes.ContentState {
        SoloLiveWidgetAttributes.ContentState(steps: 0 )
     }
     
     fileprivate static var starEyes: SoloLiveWidgetAttributes.ContentState {
         SoloLiveWidgetAttributes.ContentState(steps: 0)
     }
}

#Preview("Notification", as: .content, using: SoloLiveWidgetAttributes.preview) {
   SoloLiveWidgetLiveActivity()
} contentStates: {
    SoloLiveWidgetAttributes.ContentState.smiley
    SoloLiveWidgetAttributes.ContentState.starEyes
}
