import Foundation
import FirebaseFirestore


class ChecklistViewModel: ObservableObject {
    @Published var equipmentItems: [ChecklistItem] = [
        ChecklistItem(title: "Mask", isChecked: false),
        ChecklistItem(title: "Gas Tank", isChecked: false),
        ChecklistItem(title: "Gloves", isChecked: false),
        ChecklistItem(title: "Wetsuit", isChecked: false),
        ChecklistItem(title: "Fins", isChecked: false)
    ]
    
    @Published var additionalEquipmentItems: [ChecklistItem] = [
        ChecklistItem(title: "Dive Computer", isChecked: false),
        ChecklistItem(title: "Surface Marker Buoy", isChecked: false),
        ChecklistItem(title: "Dive Knife", isChecked: false)
    ]
    
    @Published var safetyItems: [ChecklistItem] = [
        ChecklistItem(title: "First Aid Kit", isChecked: false),
        ChecklistItem(title: "Emergency Oxygen", isChecked: false),
        ChecklistItem(title: "Whistle", isChecked: false)
    ]
    
    @Published var documentationItems: [ChecklistItem] = [
        ChecklistItem(title: "Diving License", isChecked: false),
        ChecklistItem(title: "Logbook", isChecked: false)
    ]
    
    @Published var personalItems: [ChecklistItem] = [
        ChecklistItem(title: "Sunscreen", isChecked: false),
        ChecklistItem(title: "Water Bottle", isChecked: false)
    ]
    
    func addItem(to section: ChecklistSection, title: String) {
        let newItem = ChecklistItem(title: title, isChecked: false)
        switch section {
        case .equipment:
            equipmentItems.append(newItem)
        case .additionalEquipment:
            additionalEquipmentItems.append(newItem)
        case .safety:
            safetyItems.append(newItem)
        case .documentation:
            documentationItems.append(newItem)
        case .personal:
            personalItems.append(newItem)
        }
    }
    
    func removeItem(from section: ChecklistSection, at index: Int) {
        switch section {
        case .equipment:
            equipmentItems.remove(at: index)
        case .additionalEquipment:
            additionalEquipmentItems.remove(at: index)
        case .safety:
            safetyItems.remove(at: index)
        case .documentation:
            documentationItems.remove(at: index)
        case .personal:
            personalItems.remove(at: index)
        }
    }
    
    func resetAllItems() {
            equipmentItems.indices.forEach { index in
                equipmentItems[index].isChecked = false
            }
            additionalEquipmentItems.indices.forEach { index in
                additionalEquipmentItems[index].isChecked = false
            }
            safetyItems.indices.forEach { index in
                safetyItems[index].isChecked = false
            }
            documentationItems.indices.forEach { index in
                documentationItems[index].isChecked = false
            }
            personalItems.indices.forEach { index in
                personalItems[index].isChecked = false
            }
        }
}

enum ChecklistSection {
    case equipment
    case additionalEquipment
    case safety
    case documentation
    case personal
}





