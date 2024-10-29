//
//  RunHistoryView.swift
//  Solo
//
//  Created by William Kim on 10/27/24.
//

import Foundation
import SwiftUI
import SwiftData

struct RunHistoryView: View {
    
    @Environment(\.modelContext) var modelContext
    @State var runListData : [Run] = []
    
    @State private var hasMoreData = true
    @State private var pageNumber: Int = 0
    let pageSize: Int = 5
    
  
    func fetchNewRuns() {
        
        guard hasMoreData else {return}
        
        var fetchDescriptor = FetchDescriptor<Run>(sortBy: [SortDescriptor(\.postedDate, order: .reverse)])
        fetchDescriptor.fetchLimit = 5
        fetchDescriptor.fetchOffset = pageNumber * pageSize
        
        print("fetching")
        
        do {
            let newRuns = try modelContext.fetch(fetchDescriptor)
            runListData.append(contentsOf: newRuns)
            
            if newRuns.count < pageSize {
                hasMoreData = false
            } else {
                pageNumber += 1 // Only increment if there are more items to fetch
            }
        } catch {
            print("Fetch error \(error)")
        }
        
        
    }

    var body: some View {
    
        VStack {
            if !runListData.isEmpty {
                // List View
                ScrollView(showsIndicators: false) {
                    LazyVStack {
                        ForEach(runListData) { run in
                            NavigationLink(destination: Text("test")) {
                                
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(run.startTime.formatted(
                                            .dateTime
                                                .day()
                                                .month(.abbreviated)
                                        ))
                                        .font(Font.custom("Koulen-Regular", size: 20))
                                        .foregroundStyle(.white)
                                        .fontWeight(.semibold)
                                        
                                        
                                        Text("\(convertDateToString(date: run.startTime)) - \(convertDateToString(date: run.endTime))")
                                            .foregroundStyle(TEXT_LIGHT_GREY)
                                            .font(.subheadline)
                                        
                                        HStack(alignment: .center) {
                                            CustomPin(background: Color.white, foregroundStyle: DARK_GREY)
                                            Text((run.endLocation.name)!)
                                                .foregroundStyle(.white)
                                                .padding(.leading, 4)
                                                .padding(.bottom, 4)
                                                .font(.system(size: 14))
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    if let uiImage = UIImage(data: run.routeImage) {
                                        VStack {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFill()
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                        }
                                        .frame(width: 80, height: 80 )
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .onAppear {
                                    if run == runListData.last {
                                        fetchNewRuns()
                                    }
                                }
                            }
                        }
                        
                    }
                    .listStyle(PlainListStyle())
                }
            }
        }
        .onAppear {
            fetchNewRuns()
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
        
    }
}
