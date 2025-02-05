//
//  RunHistoryView.swift
//  Solo
//
//  Created by William Kim on 10/27/24.
//

import Foundation
import SwiftUI
import SwiftData
import Algorithms


/**
 Renders an organized list of runs sorted by their corresponding months. Each run preview item can be deleted by
 swiping left on an entry.
 */
struct RunHistoryView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Run.postedDate, order: .reverse) var runs: [Run]
    @State private var isExpanded: Set<String> = []
    var sectionedRuns: [(String, [Run])] { chunkRuns(runsToChunk: runs)}

    private var sectionDateFormatter = DateFormatter()
   
    init() {
        sectionDateFormatter.dateFormat = "MMM yyyy"
    }
    
    func chunkRuns(runsToChunk: [Run]) -> [(String, [Run])] {
        let chunks = runsToChunk.chunked(on: {
            Calendar.current.dateComponents([.year, .month], from: $0.postedDate)
        })
        return chunks.map {
            let chunkDate = Calendar.current.date(from: $0.0)
            return (sectionDateFormatter.string(from: chunkDate!), Array($0.1))
        }
    }
    
    func deleteRuns(at offsets: IndexSet) {
        
        // Delete any other run that uses the same route destination or endPlacemark
        for offset in offsets {
            let run = runs[offset]
            modelContext.delete(run)
        }
    }

    var body: some View {
        
        NavigationStack {
            
            Spacer().frame(height: 16)

            VStack {
                if !runs.isEmpty {
                    List {
                        ForEach(sectionedRuns, id: \.self.0) { title, runs in
                            Section(
                                title,
                                isExpanded: Binding<Bool> (
                                   get: {
                                       return isExpanded.contains(title)
                                   },
                                   set: { isExpanding in
                                       if isExpanding {
                                           isExpanded.insert(title)
                                       } else {
                                           isExpanded.remove(title)
                                       }
                                   })
                            
                            ) {
                                ForEach(runs) { run in
                            
                                    ZStack(alignment: .topLeading) {
                                        // Ovleray an empty view to hide the default navigation arrow icon
                                        NavigationLink(destination: RunDetailView(runData: run)) {EmptyView()}.opacity(0)
                                        
                                        // Run preview content
                                        if let endPlacemark = run.endPlacemark {
                                            
                                            HStack(alignment: .top, spacing: 4) {
                                                
                                                if let data = run.routeImage {
                                                    ZStack(alignment: .topTrailing) {
                                                        Image(uiImage: UIImage(data: data)!)
                                                            .resizable()
                                                            .scaledToFill()
                                                            .clipShape(RoundedRectangle(cornerRadius: 20))
                                                            .overlay {
                                                                
                                                                if endPlacemark.isCustomLocation {
                                                                    Circle()
                                                                        .strokeBorder(.black, lineWidth: 2)
                                                                        .background(Circle().fill(.yellow))
                                                                        .frame(width: 12, height: 12)
                                                                        .offset(x: 10, y: -10)
                                                                }
                                                            }
                                                    }
                                                    .frame(width: 24, height: 24 )
                                                    .padding(.trailing, 4)
                                                }
                                                
                                                VStack(alignment: .leading) {
                                                    Text(formattedDayAndTimeRange(startDate: run.startTime, endDate: run.endTime))
                                                        .foregroundStyle(.white)
                                                        .font(.caption)
                                                    
                                                    Text(endPlacemark.name)
                                                        .foregroundStyle(TEXT_LIGHT_GREY)
                                                        .font(.subheadline)
                                                }
                                                
                                                Spacer()
                                            }
                                        }
                                    }
                                    .padding(.vertical, 4)
                                    
                                }
                                .onDelete(perform: deleteRuns)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
//                                .alignmentGuide(.listRowSeparatorLeading) { _ in
//                                    return 0
//                                }
                            }
                            .padding(0)
                        }
                    }
                    .listStyle(.sidebar)
                    .scrollIndicators(.hidden)
                    .scrollContentBackground(.hidden)
                }
                else {
                    ContentUnavailableView(
                        "No runs were found",
                        systemImage: "figure.run.square.stack.fill",
                        description: Text("Start a new run by tapping on the + symbol")
                    )
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Run History")
                        .font(.title2)
                        .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                        .foregroundColor(.white)
                }
            }
            .background(.black)
            .toolbarBackground(.black, for: .navigationBar)
            .preferredColorScheme(.dark)
            
        }
    }
}
