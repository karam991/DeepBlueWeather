//
//  DivePlannerViewModel.swift
//  DeepBlueWeather
//
//  Created by Abdulkarim Alnaser on 28.03.24.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import MapKit

class DivePlannerViewModel: ObservableObject {
    @Published var divePlans: [DivePlan] = []
    @Published var selectedDivePlan: DivePlan?
    @Published var nextDivePlan: DivePlan?
    private var listener: ListenerRegistration? = nil
    var weatherViewModel: WeatherViewModel
    
    init(weatherViewModel: WeatherViewModel) {
        self.weatherViewModel = weatherViewModel
    }
    
    // Fetching coordinates and weather for a given location
    func fetchCoordinatesAndWeather(for location: String) {
        
        Task {
            await self.weatherViewModel.fetchWeatherDataByLocation(location: location)
        }
        
        
    }
    
    func selectDivePlan(_ divePlan: DivePlan) {
        selectedDivePlan = divePlan
        fetchCoordinatesAndWeather(for: divePlan.location)
    }
    
    // CRUD operations
    func createDivePlan(location: String, date: String, depth: Int, duration: Int, deepDive: Bool, nightDive: Bool) {
        if let userId = Auth.auth().currentUser?.uid {
            let newPlan = DivePlan(userId: userId, location: location, date: date, depth: depth, duration: duration, deepDive: deepDive, nightDive: nightDive)
            do {
                try FirebaseManager.shared.fireStore.collection("divePlans").addDocument(from: newPlan)
            } catch {
                print("Error creating dive plan: \(error)")
            }
        }
    }
    
    func updateDivePlan(updatedPlan: DivePlan) {
        guard let planId = updatedPlan.id else { return }
        do {
            try FirebaseManager.shared.fireStore.collection("divePlans").document(planId).setData(from: updatedPlan)
        } catch {
            print("Failed to update dive plan: \(error)")
        }
    }
    
    func deleteDivePlan(at index: Int) {
        guard index < divePlans.count, let planId = divePlans[index].id else {
            print("Invalid index or dive plan ID")
            return
        }
        
        FirebaseManager.shared.fireStore.collection("divePlans").document(planId).delete { error in
            if let error = error {
                print("Error deleting dive plan: \(error)")
            } else {
                DispatchQueue.main.async {
                    self.divePlans.remove(at: index)
                }
            }
        }
    }
    
    // Reading all dive plans for the current user
    func readDivePlans() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("User ID not found")
            return
        }
        
        listener = FirebaseManager.shared.fireStore.collection("divePlans").whereField("userId", isEqualTo: userId)
            .addSnapshotListener { [weak self] (querySnapshot, error) in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error reading dive plans: \(error)")
                    return
                }
                
                self.divePlans = querySnapshot?.documents.compactMap { document in
                    try? document.data(as: DivePlan.self)
                } ?? []
            }
    }
    
    func removeListener() {
        listener?.remove()
        listener = nil
    }
}
