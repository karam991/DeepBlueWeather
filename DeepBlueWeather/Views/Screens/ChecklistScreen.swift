//
//  ChecklistScreen.swift
//  DeepBlueWeather
//
//  Created by Abdulkarim Alnaser on 26.02.24.
//

import SwiftUI

struct ChecklistScreen: View {
    @State private var equipmentItems = [
        "Mask", "Gas Tank", "Gloves", "Wetsuit", "Fins"
    ]
    
    @State private var additionalEquipment = [String]()
    @State private var safetyItems = ["First Aid Kit", "Emergency Oxygen", "Whistle"]
    @State private var documentationItems = ["Diving License", "Logbook"]
    @State private var personalItems = ["Sunscreen", "Water Bottle"]
    
    var body: some View {
        List {
            Text("Checklist")
                .font(.title)
                .padding()
            
            SectionView(title: "Equipment", items: $equipmentItems)
            SectionView(title: "Additional Equipment", items: $additionalEquipment)
            SectionView(title: "Safety", items: $safetyItems)
            SectionView(title: "Documentation", items: $documentationItems)
            SectionView(title: "Personal", items: $personalItems)
            
        }
    }
}

struct SectionView: View {
    var title: String
    @Binding var items: [String]
    
    var body: some View {
        Section(header: Text(title)) {
            ForEach(items, id: \.self) { item in
                ChecklistItemView(title: item)
            }
            
            Button(action: {
                addItem()
            }) {
                HStack {
                    Image(systemName: "plus.circle")
                    Text("Add Item")
                }
            }
        }
    }
    
    func addItem() {
        
    }
}

struct ChecklistItemView: View {
    var title: String
    @State private var isChecked = false
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                .foregroundColor(isChecked ? .green : .black)
                .onTapGesture {
                    isChecked.toggle()
                }
        }
        .padding(.vertical, 4)
        
    }
}

struct ChecklistScreen_Previews: PreviewProvider {
    static var previews: some View {
        ChecklistScreen()
    }
}


