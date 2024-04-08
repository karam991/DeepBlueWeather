//
//  DivePlannerScreen.swift
//  DeepBlueWeather
//
//  Created by Abdulkarim Alnaser on 26.02.24.
//

import SwiftUI

struct DivePlan: Identifiable {
    var id = UUID()
    var userId : String
    var location: String
    var date: String
    var depth: Int
    var duration: Int
    var deepDive: Bool
    var nightDive: Bool
}


struct DivePlannerScreen: View {
    @StateObject var viewModel = DivePlannerViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Created Dive Plans")
                
                List(viewModel.divePlans) { plan in
                    VStack(alignment: .leading) {
                        Text("Location: \(plan.location)")
                        Text("Date: \(plan.date)")
                        Text("Depth: \(plan.depth) meters")
                        Text("Duration: \(plan.duration) minutes")
                        Text("Deep Dive: \(plan.deepDive ? "Yes" : "No")")
                        Text("Night Dive: \(plan.nightDive ? "Yes" : "No")")
                    }
                }
                
                NavigationLink(destination: DivePlannerSheetView(divePlannerViewModel: self.viewModel)) {
                    Image(systemName: "plus")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                        .padding()
                }
                
            }
        }
        .padding()
        .navigationBarTitle("Dive Planner")
    }
}


struct DivePlannerScreen_Previews: PreviewProvider {
    static var previews: some View {
        DivePlannerScreen()
    }
}


/*            Button(action: {
 // Placeholder action for adding new dive plan
 let newPlan = DivePlan(location: "New Location", date: "New Date", depth: 0, duration: 0, deepDive: false, nightDive: false)
 divePlans.append(newPlan)
 }) {
 Image(systemName: "plus")
 */
