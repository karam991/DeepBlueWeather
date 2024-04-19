//
//  DivePlannerSheetView.swift
//  DeepBlueWeather
//
//  Created by Abdulkarim Alnaser on 20.03.24.
//

import SwiftUI

struct DivePlannerSheetView: View {
    @ObservedObject var divePlannerViewModel : DivePlannerViewModel
    
    @State private var diveLocation: String = ""
    @State private var diveDate: String = ""
    @State private var diveDepth: Int = 0
    @State private var diveDuration: Int = 0
    @State private var deepDiveSelected: Bool = false
    @State private var nightDiveSelected: Bool = false
    
    var body: some View {
        VStack {
            Text("Dive Planner")
                .font(.title)
                .fontWeight(.bold)
                .padding()
                .foregroundColor(.white)
            
            // Dive location selection
            TextField("Where", text: $diveLocation)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            // Dive date selection
            TextField("When (DD.MM.YY)", text: $diveDate)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            // Depth and duration selection
            HStack {
                VStack {
                    // Dive depth selection
                    HStack {
                        Text("Depth")
                        Picker("", selection: $diveDepth) {
                            ForEach(0..<41) { depth in
                                Text("\(depth) meters")
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    .padding()
                    
                    // Dive duration selection
                    HStack {
                        Text("Duration")
                        Picker("", selection: $diveDuration) {
                            ForEach(0..<121) { duration in
                                Text("\(duration) minutes")
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    .padding()
                }
                .padding()
                
                // Mini map
                HStack {
                    Image(systemName: "map.fill")
                        .foregroundColor(.blue)
                        .padding()
                }
                .padding()
            }
            
            // Dive type selection
            HStack {
                Toggle(isOn: $deepDiveSelected) {
                    Text("Deep Dive")
                }
                .padding()
                
                Toggle(isOn: $nightDiveSelected) {
                    Text("Night Dive")
                }
                .padding()
            }
            .padding()
            
            // Button for creating checklist and Weather widget
            HStack {
                Button(action: {
                    // Action to create checklist
                    //  update the  dive plan with the entered details
                    self.divePlannerViewModel.createDivePlan(location: diveLocation, date: diveDate, depth: diveDepth, duration: diveDuration, deepDive: deepDiveSelected, nightDive: nightDiveSelected)
                }) {
                    Text("Create Checklist")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .padding()
                
                HStack {
                    Image(systemName: "sun.max.fill")
                        .foregroundColor(.yellow)
                    Text("Sunny")
                        .foregroundColor(.white)
                    
                    Image(systemName: "thermometer")
                        .foregroundColor(.blue)
                    Text("25°C")
                        .foregroundColor(.white)
                }
            }
            .padding()
            
            Spacer()
        }
        .padding()
        
    }
}

/*#Preview {
    DivePlannerSheetView(divePlannerViewModel: .init())
}*/

