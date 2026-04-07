//
//  ChecklistScreen.swift
//  DeepBlueWeather
//
//  Created by Abdulkarim Alnaser on 20.03.24.
//

import SwiftUI

struct ChecklistScreen: View {
    @StateObject var viewModel = ChecklistViewModel()
    @State private var showingAddItem = false
    @State private var newItemTitle = ""
    @State private var selectedSection: ChecklistSection = .equipment

    var body: some View {
        NavigationView {
            List {
                ChecklistSectionView(
                    title: "Essential Equipment",
                    items: $viewModel.equipmentItems,
                    section: .equipment,
                    onDelete: { viewModel.removeItem(from: .equipment, at: $0) }
                )

                ChecklistSectionView(
                    title: "Additional Equipment",
                    items: $viewModel.additionalEquipmentItems,
                    section: .additionalEquipment,
                    onDelete: { viewModel.removeItem(from: .additionalEquipment, at: $0) }
                )

                ChecklistSectionView(
                    title: "Safety",
                    items: $viewModel.safetyItems,
                    section: .safety,
                    onDelete: { viewModel.removeItem(from: .safety, at: $0) }
                )

                ChecklistSectionView(
                    title: "Documentation",
                    items: $viewModel.documentationItems,
                    section: .documentation,
                    onDelete: { viewModel.removeItem(from: .documentation, at: $0) }
                )

                ChecklistSectionView(
                    title: "Personal",
                    items: $viewModel.personalItems,
                    section: .personal,
                    onDelete: { viewModel.removeItem(from: .personal, at: $0) }
                )
            }
            .listStyle(InsetGroupedListStyle())
            .navigationBarTitle("Dive Checklist")
            .navigationBarItems(
                leading: Button("Reset") {
                    viewModel.resetAllItems()
                }
                .foregroundColor(.red),
                trailing: Button(action: {
                    showingAddItem = true
                }) {
                    Image(systemName: "plus")
                }
            )
            .sheet(isPresented: $showingAddItem) {
                AddChecklistItemView(
                    viewModel: viewModel,
                    selectedSection: $selectedSection,
                    newItemTitle: $newItemTitle,
                    isPresented: $showingAddItem
                )
            }
        }
    }
}

// MARK: - Section View
struct ChecklistSectionView: View {
    let title: String
    @Binding var items: [ChecklistItem]
    let section: ChecklistSection
    let onDelete: (Int) -> Void

    var body: some View {
        Section(header: Text(title)) {
            ForEach(items.indices, id: \.self) { index in
                ChecklistItemRow(item: $items[index])
            }
            .onDelete { indexSet in
                indexSet.forEach { onDelete($0) }
            }
        }
    }
}

// MARK: - Item Row
struct ChecklistItemRow: View {
    @Binding var item: ChecklistItem

    var body: some View {
        HStack {
            Image(systemName: item.isChecked ? "checkmark.square.fill" : "square")
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundColor(item.isChecked ? .green : .gray)
                .onTapGesture {
                    item.isChecked.toggle()
                }

            Text(item.title)
                .padding(.leading)
                .foregroundColor(.primary)

            Spacer()
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Add Item Sheet
struct AddChecklistItemView: View {
    @ObservedObject var viewModel: ChecklistViewModel
    @Binding var selectedSection: ChecklistSection
    @Binding var newItemTitle: String
    @Binding var isPresented: Bool

    let sections: [(String, ChecklistSection)] = [
        ("Essential Equipment", .equipment),
        ("Additional Equipment", .additionalEquipment),
        ("Safety", .safety),
        ("Documentation", .documentation),
        ("Personal", .personal)
    ]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Item Name")) {
                    TextField("e.g. Underwater Camera", text: $newItemTitle)
                }

                Section(header: Text("Category")) {
                    Picker("Category", selection: $selectedSection) {
                        ForEach(sections, id: \.1) { name, section in
                            Text(name).tag(section)
                        }
                    }
                    .pickerStyle(.inline)
                }
            }
            .navigationBarTitle("New Item", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    newItemTitle = ""
                    isPresented = false
                },
                trailing: Button("Add") {
                    if !newItemTitle.trimmingCharacters(in: .whitespaces).isEmpty {
                        viewModel.addItem(to: selectedSection, title: newItemTitle)
                        newItemTitle = ""
                        isPresented = false
                    }
                }
                .disabled(newItemTitle.trimmingCharacters(in: .whitespaces).isEmpty)
            )
        }
    }
}

struct ChecklistScreen_Previews: PreviewProvider {
    static var previews: some View {
        ChecklistScreen()
    }
}
