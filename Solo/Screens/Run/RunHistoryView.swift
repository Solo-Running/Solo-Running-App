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
                            Section {
                                ForEach(runs) { run in
                                    
                                    ZStack(alignment: .topLeading) {
                                        // Ovleray an empty view to hide the default navigation arrow icon
                                        NavigationLink(destination: RunDetailView(runData: run)) {EmptyView()}.opacity(0)
                                        
                                        
                                        // Rounded rectangle container
                                        VStack {
                                            
                                            // Run preview content
                                            HStack(alignment: .top, spacing: 16) {
                                                
                                                if let data = run.routeImage {
                                                    VStack {
                                                        Image(uiImage: UIImage(data: data)!)
                                                            .resizable()
                                                            .scaledToFill()
                                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                                    }
                                                    .frame(width: 64, height: 64 )
                                                }
                                                
                                                                                                
                                                VStack(alignment: .leading, spacing: 16) {
                                                    
                                                    // Date and elapse times
                                                    HStack {
                                                        HStack(spacing: 8) {
                                                            
                                                            Image(systemName: "calendar")
                                                                .foregroundStyle(TEXT_LIGHT_GREY)
                                                            
                                                            Text(run.startTime.formatted(
                                                                .dateTime.weekday(.abbreviated).day()
                                                            ))
                                                            .foregroundStyle(TEXT_LIGHT_GREY)
                                                            .fontWeight(.semibold)
                                                        }
                                                        
                                                        Spacer()

                                                        Text(formattedElapsedTime(from: run.startTime, to: run.endTime))
                                                            .foregroundStyle(TEXT_LIGHT_GREY)
                                                            .fontWeight(.semibold)
                                                        
                                                    }
                                                    
                                                    // Step count
                                                    Text("\(run.steps) steps")
                                                        .font(.title2)
                                                        .fontWeight(.semibold)
                                                        .foregroundStyle(.white)
                                                }
                                                .frame(maxWidth: .infinity)
                                                
                                                Spacer()
                                            }
                                            .padding(EdgeInsets(top: 16, leading: 16, bottom: 8, trailing: 16))
                                            
                                            
                                            Divider()
                                            
                                            HStack(alignment: .center, spacing: 8) {
                                                if let endPlacemark = run.endPlacemark {

                                                    Group {
                                                        if endPlacemark.isCustomLocation {
                                                            Circle()
                                                                .strokeBorder(DARK_GREY, lineWidth: 2)
                                                                .background(Circle().fill(.yellow))
                                                                .frame(width: 16, height: 16)
                                                        }
                                                        else {
                                                            Circle()
                                                                .strokeBorder(DARK_GREY, lineWidth: 2)
                                                                .background(Circle().fill(LIGHT_GREY))
                                                                .frame(width: 16, height: 16)
                                                        }
                                                    }


                                                    Text(endPlacemark.name)
                                                        .foregroundStyle(.white)
                                                        .font(.subheadline)
                                                        .fontWeight(.semibold)
                                                    
                                                    Spacer()
                                                }


                                            }
                                            .padding(EdgeInsets(top: 8, leading: 16, bottom: 16, trailing: 16))
                                        }
                                        .background(RoundedRectangle(cornerRadius: 12).fill(DARK_GREY))
                                        
                                    }
                                }
                                .onDelete(perform: deleteRuns)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .padding(0)
                                
                            } header: {
                                Text(title).font(.subheadline).fontWeight(.semibold)
                            }
                            
                        }
                    }
                    .listStyle(.plain)
                    .scrollIndicators(.hidden)
                    .scrollContentBackground(.hidden)
                    .padding(0)

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
