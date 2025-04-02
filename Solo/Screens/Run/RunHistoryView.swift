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
    
    @State private var showRunDetailView: Bool = false
    @State private var selectedRun: Run?
    
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
                        ForEach(sectionedRuns, id: \.self.0) { title, runsThisMonth in
                            Section {
                                ForEach(runsThisMonth) { run in
                                    
                                    // Rounded rectangle container
                                    VStack {
                                        
                                        // Run preview content
                                        HStack(alignment: .top, spacing: 16) {
                                          
                                            if let routeImage = run.routeImage {
                                                VStack {
                                                    Image(uiImage: UIImage(data: routeImage)!)
                                                        .resizable()
                                                        .scaledToFill()
                                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                                }
                                                .frame(width: 54, height: 54)
                                                .padding(.trailing, 8)
                                            }
                                            
                                            else if let breadCrumbImage = run.breadCrumbImage {
                                                VStack {
                                                    Image(uiImage: UIImage(data: breadCrumbImage)!)
                                                        .resizable()
                                                        .scaledToFill()
                                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                                }
                                                .frame(width: 54, height: 54)
                                                .padding(.trailing, 8)
                                            }
                                            else {
                                                VStack(alignment: .center) {
                                                    Image(systemName: "photo.fill")
                                                        .foregroundStyle(TEXT_LIGHT_GREY)
                                                        .frame(width: 54, height: 54)
                                                        .background(RoundedRectangle(cornerRadius: 8).fill(LIGHT_GREY))
                                                }
                                                .frame(width: 54, height: 54)
                                                .padding(.trailing, 8)
                                            }
                                            
                                            
                                            VStack(alignment: .leading, spacing: 8) {
                                                
                                                // Date and elapse times
                                                HStack {
                                                    
                                                    Text(run.startTime.formatted(
                                                        .dateTime.weekday(.abbreviated).day()
                                                    ))
                                                    .foregroundStyle(TEXT_LIGHT_GREY)
                                                    
                                                    Spacer()
                                                    
                                                    Text(formattedElapsedTime(from: run.startTime, to: run.endTime))
                                                        .font(.subheadline)
                                                        .foregroundStyle(TEXT_LIGHT_GREY)
                                                        .multilineTextAlignment(.trailing)
                                                }
                                                
                                                // Step count
                                                Text("\(run.steps) steps")
                                                    .font(.title2)
                                                    .fontWeight(.semibold)
                                                    .foregroundStyle(.white)
                                                
                                            }
                                            .frame(maxWidth: .infinity)
                                            
                                        }
                                        .padding(EdgeInsets(top: 16, leading: 16, bottom: 8, trailing: 16))
                                        
                                        
                                        Divider()
                                        
                                        HStack(alignment: .center, spacing: 8) {
                                            if let endPlacemark = run.endPlacemark {
                                                
                                                Group {
                                                    if endPlacemark.isCustomLocation {
                                                        Circle()
                                                            .strokeBorder(.yellow, lineWidth: 2)
                                                            .background(Circle().fill(.yellow))
                                                            .frame(width: 12, height: 12)
                                                    }
                                                    else {
                                                        Circle()
                                                            .strokeBorder(.red, lineWidth: 2)
                                                            .background(Circle().fill(.red))
                                                            .frame(width: 12, height: 12)
                                                    }
                                                }
                                                
                                                
                                                Text(endPlacemark.name)
                                                    .foregroundStyle(TEXT_LIGHT_GREY)
                                                    .font(.subheadline)
                                                    .fontWeight(.semibold)
                                                    .lineLimit(1)
                                                    .truncationMode(.tail)
                                                
                                                Spacer()
                                            }
                                        }
                                        .padding(EdgeInsets(top: 8, leading: 16, bottom: 16, trailing: 16))
                                    }
                                    .background(RoundedRectangle(cornerRadius: 12).fill(DARK_GREY))
                                    .onTapGesture {
                                        selectedRun = run
                                    }
                                   
                                }
                                .onDelete(perform: deleteRuns)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .padding(0)
                                
                            } header: {
                                HStack {
                                    Text(title)
                                        .font(.subheadline).fontWeight(.semibold).padding(.vertical, 8)
                                    
                                    Spacer()
                                    
                                    if runsThisMonth.count != 1 {
                                        Text("\(runsThisMonth.count) runs")
                                            .font(.subheadline).fontWeight(.semibold).padding(.vertical, 8)
                                    } else {
                                        Text("\(runsThisMonth.count) run")
                                            .font(.subheadline).fontWeight(.semibold).padding(.vertical, 8)
                                    }
                                    
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollIndicators(.hidden)
                    .scrollContentBackground(.hidden)
                    .padding(0)
                    .onChange(of: selectedRun) {_, new in
                        if new != nil {
                            showRunDetailView = true
                        }
                    }
                    .fullScreenCover(isPresented: $showRunDetailView, onDismiss: {
                        selectedRun = nil
                    }) {
                        RunDetailView(runData: selectedRun!, showRunDetailView: $showRunDetailView)
                    }
                    
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
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            .background(.black)
            .toolbarBackground(.black, for: .navigationBar)
            .preferredColorScheme(.dark)
            
        }
    }
}
