//
//  ChecklistSheetView.swift
//  DeepBlueWeather
//
//  Created by Abdulkarim Alnaser on 20.03.24.
//

import SwiftUI

struct ChecklistScreen: View {
    @StateObject var viewModel = ChecklistViewModel()
    
    var body: some View {
        List {
            SectionView(title: "Equipment",viewModel: viewModel, items: $viewModel.equipmentItems, category: .equipment)
            
            
            SectionView(title: "Additional Equipment",viewModel: viewModel, items: $viewModel.additionalEquipmentItems,category: .additionalEquipment)
            
            
            SectionView(title: "Safety",viewModel: viewModel, items: $viewModel.safetyItems,category: .safety)
            
            
            SectionView(title: "Documentation",viewModel: viewModel, items: $viewModel.documentationItems,category: .documentation)
            
            
            SectionView(title: "Personal",viewModel: viewModel, items: $viewModel.personalItems,category: .personal)
        }
        .listStyle(GroupedListStyle())
        .navigationTitle("Checklist")
        .navigationBarItems(trailing:
                                Button(action: {
            viewModel.resetAllItems()
        }) {
            Image(systemName: "arrow.uturn.backward.circle")
        }
        )
    }
}

struct SectionView: View {
    var title: String
    @ObservedObject var viewModel : ChecklistViewModel
    @Binding var items: [ChecklistItem]
    let category : ChecklistSection
    var body: some View {
        Section(header: Text(title)) {
            ForEach(items.indices, id: \.self) { index in
                ChecklistItemView(item: $items[index])
            }
            
            Button(action: {
                viewModel.addItem(to: category, title: "New Item")
            }) {
                Label("Add New Item", systemImage: "plus")
            }
        }
    }
}

struct ChecklistItemView: View {
    @Binding var item: ChecklistItem
    
    
    var body: some View {
        HStack {
            Text(item.title)
            Spacer()
            Image(systemName: item.isChecked ? "checkmark.square.fill" : "square")
                .foregroundColor(item.isChecked ? .green : .black)
                .onTapGesture {
                    item.isChecked.toggle()
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

