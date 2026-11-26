//
//  DivePlannerViewModel.swift
//  DeepBlueWeather
//
//  Created by Karam Alnaser on 28.03.24.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import MapKit
import WidgetKit

class DivePlannerViewModel: ObservableObject {
    @Published var showingDivePlannerSheet = false

    @Published var divePlans: [DivePlan] = []
    @Published var selectedDivePlan: DivePlan?
    @Published var currentLocationCoordinate: CLLocationCoordinate2D?
    private var listener: ListenerRegistration? = nil
    var weatherViewModel: WeatherViewModel
    
    init(weatherViewModel: WeatherViewModel) {
        self.weatherViewModel = weatherViewModel
    }
    
    // Enhanced method to fetch coordinates and weather
    func fetchCoordinatesAndWeather(for location: String) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(location) { [weak self] (placemarks, error) in
            guard let self = self, let placemark = placemarks?.first, error == nil else {
                print("Geocoding error: \(error?.localizedDescription ?? "No error provided")")
                return
            }

            let location = placemark.location?.coordinate
            if let location = location {
                self.currentLocationCoordinate = location
                Task {
                    await self.weatherViewModel.fetchWeatherDataByCoordinates(latitude: location.latitude, longitude: location.longitude)
                }
            }
        }
    }
    
    func selectDivePlan(_ divePlan: DivePlan) {
        selectedDivePlan = divePlan
        fetchCoordinatesAndWeather(for: divePlan.location)
    }
    
    // CRUD operations remain the same as you've provided
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

    // Deletion and update functions
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
            
            }
        }
    }

    // Reading and listening to dive plans
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
                self.plansDidChange()
            }
    }
    
    // MARK: - Lists and totals

    private var plansByDate: [DivePlan] {
        divePlans.sorted { ($0.parsedDate ?? .distantFuture) < ($1.parsedDate ?? .distantFuture) }
    }

    /// Not yet dived, soonest first.
    var upcomingPlans: [DivePlan] { plansByDate.filter { !$0.isPast && $0.log == nil } }

    /// Past or logged, newest first.
    var pastPlans: [DivePlan] { plansByDate.filter { $0.isPast || $0.log != nil }.reversed() }

    var totalMinutes: Int { divePlans.reduce(0) { $0 + $1.duration } }

    var maxDepth: Int { divePlans.map(\.depth).max() ?? 0 }

    var totals: [Fact] {
        [Fact(title: "Dives", value: "\(divePlans.count)", spoken: "\(divePlans.count) dives"),
         Fact(title: "Bottom time", value: "\(totalMinutes) min", spoken: "Bottom time \(totalMinutes) minutes"),
         Fact(title: "Max depth", value: "\(maxDepth) m", spoken: "Maximum depth \(maxDepth) metres")]
    }

    // MARK: - Dive log

    func saveLog(_ log: DiveLog?, for plan: DivePlan) {
        var updated = plan
        updated.log = log
        updateDivePlan(updatedPlan: updated)
    }

    // MARK: - Side effects: reminders + widget

    /// Keeps notifications and the home-screen widget in sync with the plans.
    func plansDidChange() {
        DiveReminderService.sync(with: divePlans)

        let next = divePlans
            .filter { ($0.parsedDate ?? .distantPast) > Date().addingTimeInterval(-3 * 3600) && $0.log == nil }
            .min { ($0.parsedDate ?? .distantFuture) < ($1.parsedDate ?? .distantFuture) }

        let shared = next.flatMap { plan in
            plan.parsedDate.map {
                SharedNextDive(location: plan.location.capitalized, date: $0, depth: plan.depth,
                               duration: plan.duration, nightDive: plan.nightDive, deepDive: plan.deepDive)
            }
        }
        if SharedDiveStore.save(shared) {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    func removeListener() {
        listener?.remove()
        listener = nil
    }
}
