//
//  ChecklistViewModel.swift
//  DeepBlueWeather
//

import Foundation

class ChecklistViewModel: ObservableObject {
    
    @Published var equipmentItems: [ChecklistItem] = [] {
        didSet { save() }
    }
    @Published var additionalEquipmentItems: [ChecklistItem] = [] {
        didSet { save() }
    }
    @Published var safetyItems: [ChecklistItem] = [] {
        didSet { save() }
    }
    @Published var documentationItems: [ChecklistItem] = [] {
        didSet { save() }
    }
    @Published var personalItems: [ChecklistItem] = [] {
        didSet { save() }
    }

    private let defaults = UserDefaults.standard

    init() {
        load()
    }

    // MARK: - Default Items
    private func defaultEquipmentItems() -> [ChecklistItem] {[
        ChecklistItem(title: "Mask", isChecked: false),
        ChecklistItem(title: "Gas Tank", isChecked: false),
        ChecklistItem(title: "Gloves", isChecked: false),
        ChecklistItem(title: "Wetsuit", isChecked: false),
        ChecklistItem(title: "Fins", isChecked: false)
    ]}

    private func defaultAdditionalEquipmentItems() -> [ChecklistItem] {[
        ChecklistItem(title: "Dive Computer", isChecked: false),
        ChecklistItem(title: "Surface Marker Buoy", isChecked: false),
        ChecklistItem(title: "Dive Knife", isChecked: false)
    ]}

    private func defaultSafetyItems() -> [ChecklistItem] {[
        ChecklistItem(title: "First Aid Kit", isChecked: false),
        ChecklistItem(title: "Emergency Oxygen", isChecked: false),
        ChecklistItem(title: "Whistle", isChecked: false)
    ]}

    private func defaultDocumentationItems() -> [ChecklistItem] {[
        ChecklistItem(title: "Diving License", isChecked: false),
        ChecklistItem(title: "Logbook", isChecked: false)
    ]}

    private func defaultPersonalItems() -> [ChecklistItem] {[
        ChecklistItem(title: "Sunscreen", isChecked: false),
        ChecklistItem(title: "Water Bottle", isChecked: false)
    ]}

    // MARK: - Persistence
    private func save() {
        let encoder = JSONEncoder()
        let categories: [(String, [ChecklistItem])] = [
            ("equipment", equipmentItems),
            ("additionalEquipment", additionalEquipmentItems),
            ("safety", safetyItems),
            ("documentation", documentationItems),
            ("personal", personalItems)
        ]
        for (key, items) in categories {
            if let encoded = try? encoder.encode(items) {
                defaults.set(encoded, forKey: key)
            }
        }
    }

    private func load() {
        let decoder = JSONDecoder()
        let loaded = decode([ChecklistItem].self, forKey: "equipment", decoder: decoder)
        equipmentItems = (loaded?.isEmpty == false) ? loaded! : defaultEquipmentItems()
        
        let loaded2 = decode([ChecklistItem].self, forKey: "additionalEquipment", decoder: decoder)
        additionalEquipmentItems = (loaded2?.isEmpty == false) ? loaded2! : defaultAdditionalEquipmentItems()
        
        let loaded3 = decode([ChecklistItem].self, forKey: "safety", decoder: decoder)
        safetyItems = (loaded3?.isEmpty == false) ? loaded3! : defaultSafetyItems()
        
        let loaded4 = decode([ChecklistItem].self, forKey: "documentation", decoder: decoder)
        documentationItems = (loaded4?.isEmpty == false) ? loaded4! : defaultDocumentationItems()
        
        let loaded5 = decode([ChecklistItem].self, forKey: "personal", decoder: decoder)
        personalItems = (loaded5?.isEmpty == false) ? loaded5! : defaultPersonalItems()
    }

    private func decode<T: Decodable>(_ type: T.Type, forKey key: String, decoder: JSONDecoder) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? decoder.decode(type, from: data)
    }

    // MARK: - Actions
    func addItem(to section: ChecklistSection, title: String) {
        let newItem = ChecklistItem(title: title, isChecked: false)
        switch section {
        case .equipment: equipmentItems.append(newItem)
        case .additionalEquipment: additionalEquipmentItems.append(newItem)
        case .safety: safetyItems.append(newItem)
        case .documentation: documentationItems.append(newItem)
        case .personal: personalItems.append(newItem)
        }
    }

    func removeItem(from section: ChecklistSection, at index: Int) {
        switch section {
        case .equipment: equipmentItems.remove(at: index)
        case .additionalEquipment: additionalEquipmentItems.remove(at: index)
        case .safety: safetyItems.remove(at: index)
        case .documentation: documentationItems.remove(at: index)
        case .personal: personalItems.remove(at: index)
        }
    }

    func resetAllItems() {
        equipmentItems = defaultEquipmentItems()
        additionalEquipmentItems = defaultAdditionalEquipmentItems()
        safetyItems = defaultSafetyItems()
        documentationItems = defaultDocumentationItems()
        personalItems = defaultPersonalItems()
    }
}

enum ChecklistSection: Hashable {
    case equipment
    case additionalEquipment
    case safety
    case documentation
    case personal
}
