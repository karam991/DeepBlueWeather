//
//  DivePlannerScreen.swift
//  DeepBlueWeather
//
//  Created by Abdulkarim Alnaser on 26.02.24.
//

import SwiftUI




struct DivePlannerScreen: View {
    @StateObject var weatherViewModel = WeatherViewModel()
    @StateObject var viewModel = DivePlannerViewModel(weatherViewModel: WeatherViewModel()) 
    var body: some View {
        NavigationView {
            VStack {
                Text("Created Dive Plans")
                
                List {
                    ForEach(viewModel.divePlans){ plan in
                        VStack(alignment: .leading) {
                            Text("Location: \(plan.location)")
                            Text("Date: \(plan.date)")
                            Text("Depth: \(plan.depth) meters")
                            Text("Duration: \(plan.duration) minutes")
                            Text("Deep Dive: \(plan.deepDive ? "Yes" : "No")")
                            Text("Night Dive: \(plan.nightDive ? "Yes" : "No")")
                        }
                    }.onDelete(perform: { indexSet in
                        viewModel.deleteDivePlan(at: indexSet.first!)
                    })
                }
                
                .onAppear(perform: {
                    viewModel.readDivePlans()
                    
                })
                
                NavigationLink(destination: DivePlannerSheetView(divePlannerViewModel: self.viewModel)) {
                    Image(systemName: "plus")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                        .padding()
                }
                
                
            }
            .padding()
            .navigationBarTitle("Dive Planner")
        }
        .environmentObject(viewModel.weatherViewModel) 

    }
}

/*struct DivePlannerScreen_Previews: PreviewProvider {
    static var previews: some View {
        DivePlannerScreen()
            .environmentObject(DivePlannerViewModel(weatherViewModel: WeatherViewModel()))
    }
}*/


