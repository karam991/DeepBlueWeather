//
//  DivePlannerViewModel.swift
//  DeepBlueWeather
//
//  Created by Abdulkarim Alnaser on 28.03.24.
//

import Foundation
import FirebaseAuth

class DivePlannerViewModel: ObservableObject {
    @Published var divePlans: [DivePlan] = []
    @Published var selectedDivePlan: DivePlan?
    
    
    func createDivePlan(location: String, date: String, depth: Int, duration: Int, deepDive: Bool, nightDive: Bool) {
        if let userId = Auth.auth().currentUser?.uid { // id for current user from firebase
            let newPlan = DivePlan(userId: userId, location: location, date: date, depth: depth, duration: duration, deepDive: deepDive, nightDive: nightDive)
            divePlans.append(newPlan)
        }
    }
}
