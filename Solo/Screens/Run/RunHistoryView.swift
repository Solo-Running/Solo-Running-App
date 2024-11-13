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

struct RunHistoryView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Run.postedDate, order: .reverse) var runs: [Run]
    
    var sectionedRuns: [(String, [Run])] {
        chunkRuns(runsToChunk: runs)
    }
    
    
    let sectionDateFormatter = DateFormatter()
   
    @State private var isExpanded: Set<String> = []
      
    
    init() {
        sectionDateFormatter.dateFormat = "MMM yyyy"
//        _isExpanded = State(initialValue: Set(sectionedRuns.map { $0.0 }))  this causes error .modelContext in view's environment to use Query
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
        
        // delete any other run that uses the same route destination or endPlacemark
        for offset in offsets {
            let run = runs[offset]
            
            
            let routeId = run.endPlacemark.id
            let fetchDescriptor = FetchDescriptor<Run>(predicate: #Predicate<Run> {
                $0.endPlacemark.id == routeId
            })
            
            do {
                let runs = try modelContext.fetch(fetchDescriptor)
                for run in runs {
                    modelContext.delete(run)
                }
            } catch {
                print("could not fetch runs with custom pin")
            }

            // delete the run from the context
            modelContext.delete(run)
        }
    }

    var body: some View {
        
        NavigationStack {
            
            Spacer().frame(height: 16)

            VStack {
                if !runs.isEmpty {
                    // List View
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
                                        // ovleray an empty view to hide the default navigation arrow icon
                                        NavigationLink(destination: RunDetailView(runData: run)) {EmptyView()}.opacity(0)
                                        
                                        // Run preview content
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text(String(getDayAndTimeRange(startDate: run.startTime, endDate: run.endTime)))
                                                    .font(.subheadline)
                                                    .fontWeight(.semibold)
                                                
                                                HStack(alignment: .center) {
                                                    if let uiImage = UIImage(data: run.routeImage) {
                                                        VStack {
                                                            Image(uiImage: uiImage)
                                                                .resizable()
                                                                .scaledToFill()
                                                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                                        }
                                                        .frame(width: 24, height: 24 )
                                                        .padding(.trailing, 4)
                                                    }
                                                    
                                                    Text("\(run.endPlacemark.name!)")
                                                        .foregroundStyle(TEXT_LIGHT_GREY)
                                                    
                                                    Spacer()

                                                }
                                            }
                                            
                                            Spacer()

//                                            CapsuleView(capsuleBackground: DARK_GREY, iconName: "", iconColor: "", text: String("\(run.steps!)"))
                                            
                                        }
                                    }
                                }
                                .onDelete(perform: deleteRuns)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)

                            }
                        }
                    }
                    .listStyle(.sidebar)
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
