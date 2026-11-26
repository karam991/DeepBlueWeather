//
//  ChecklistScreen.swift
//  DeepBlueWeather
//
//  Created by Karam Alnaser on 20.03.24.
//

import SwiftUI

extension ChecklistSection: CaseIterable {
    static var allCases: [ChecklistSection] { [.equipment, .additionalEquipment, .safety, .documentation, .personal] }

    var title: String {
        switch self {
        case .equipment: return "Essential Equipment"
        case .additionalEquipment: return "Additional Equipment"
        case .safety: return "Safety"
        case .documentation: return "Documentation"
        case .personal: return "Personal"
        }
    }

    var icon: String {
        switch self {
        case .equipment: return "backpack.fill"
        case .additionalEquipment: return "gauge.with.dots.needle.33percent"
        case .safety: return "cross.case.fill"
        case .documentation: return "doc.text.fill"
        case .personal: return "person.fill"
        }
    }

    var color: Color {
        switch self {
        case .equipment: return Theme.ocean
        case .additionalEquipment: return Theme.teal
        case .safety: return Theme.coral
        case .documentation: return Theme.sand
        case .personal: return Theme.kelp
        }
    }
}

struct ChecklistScreen: View {
    @StateObject var viewModel = ChecklistViewModel()
    @EnvironmentObject private var divePlannerViewModel: DivePlannerViewModel
    @State private var showingAddItem = false
    @State private var showingResetConfirm = false
    @State private var showNextDive = false
    @State private var newItemTitle = ""
    @State private var selectedSection: ChecklistSection = .equipment

    private func binding(for section: ChecklistSection) -> Binding<[ChecklistItem]> {
        switch section {
        case .equipment: return $viewModel.equipmentItems
        case .additionalEquipment: return $viewModel.additionalEquipmentItems
        case .safety: return $viewModel.safetyItems
        case .documentation: return $viewModel.documentationItems
        case .personal: return $viewModel.personalItems
        }
    }

    private var nextDive: DivePlan? {
        divePlannerViewModel.divePlans
            .filter { !$0.isPast }
            .min { ($0.parsedDate ?? .distantFuture) < ($1.parsedDate ?? .distantFuture) }
    }

    private var allItems: [ChecklistItem] {
        ChecklistSection.allCases.flatMap { binding(for: $0).wrappedValue }
    }

    var body: some View {
        let total = allItems.count
        let done = allItems.filter(\.isChecked).count

        List {
            Section {
                ProgressHeader(done: done, total: total)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .appear()

                if let next = nextDive {
                    Button { showNextDive = true } label: {
                        HStack(spacing: Theme.Spacing.md) {
                            IconBadge(systemName: "sparkles", color: Theme.ocean, size: 36)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Smart gear for \(next.location.capitalized)")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Theme.textPrimary)
                                Text("\(next.countdownLabel ?? "Upcoming") · based on the forecast")
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(Theme.textTertiary)
                                .accessibilityHidden(true)
                        }
                        .padding(Theme.Spacing.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                                .strokeBorder(Theme.stroke, lineWidth: 1)
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PressableStyle())
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .appear(delay: 0.08)
                }
            }

            ForEach(ChecklistSection.allCases, id: \.self) { section in
                ChecklistSectionView(
                    section: section,
                    items: binding(for: section),
                    onDelete: { viewModel.removeItem(from: section, at: $0) }
                )
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Checklist")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Reset", role: .destructive) { showingResetConfirm = true }
                    .tint(Theme.coral)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddItem = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .symbolRenderingMode(.hierarchical)
                }
                .accessibilityLabel("Add item")
            }
        }
        .navigationDestination(isPresented: $showNextDive) {
            if let next = nextDive {
                DiveDetailView(plan: next, onDelete: {
                    if let i = divePlannerViewModel.divePlans.firstIndex(where: { $0.id == next.id }) {
                        divePlannerViewModel.deleteDivePlan(at: i)
                    }
                })
            }
        }
        .onAppear {
            if divePlannerViewModel.divePlans.isEmpty { divePlannerViewModel.readDivePlans() }
        }
        .confirmationDialog("Reset checklist?", isPresented: $showingResetConfirm, titleVisibility: .visible) {
            Button("Reset All Items", role: .destructive) {
                withAnimation { viewModel.resetAllItems() }
            }
        } message: {
            Text("All items will be unchecked and custom items removed.")
        }
        .sheet(isPresented: $showingAddItem) {
            AddChecklistItemView(
                viewModel: viewModel,
                selectedSection: $selectedSection,
                newItemTitle: $newItemTitle,
                isPresented: $showingAddItem
            )
            .presentationDetents([.medium, .large])
        }
    }
}

// MARK: - Progress header

private struct ProgressHeader: View {
    let done: Int
    let total: Int

    private var progress: Double { total == 0 ? 0 : Double(done) / Double(total) }
    private var complete: Bool { total > 0 && done == total }
    @State private var celebrate = 0
    @ScaledMetric(relativeTo: .title3) private var ringSize: CGFloat = 76
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Theme.Spacing.md))
            : AnyLayout(HStackLayout(spacing: Theme.Spacing.lg))

        layout {
            gauge

            VStack(alignment: .leading, spacing: 4) {
                Text(complete ? "Ready to dive" : "Pre-dive check")
                    .font(complete ? .title2.weight(.bold) : .headline)
                    .foregroundStyle(complete ? Theme.kelp : Theme.textPrimary)
                    .contentTransition(.opacity)
                Text("\(done) of \(total) items packed")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                    .contentTransition(.numericText(value: Double(done)))
            }
            Spacer(minLength: 0)
        }
        .card()
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: done)
        .sensoryFeedback(.success, trigger: celebrate)
        .onChange(of: done) { old, new in
            if new == total && total > 0 && old < new { celebrate += 1 }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(complete ? "Ready to dive" : "Pre-dive check")
        .accessibilityValue("\(done) of \(total) items packed, \(Int(progress * 100)) percent")
    }

    /// A porthole that fills with water as items are packed.
    private var gauge: some View {
        ZStack {
            Circle().fill(Theme.ocean.opacity(0.08))
            WaterFill(level: progress)
                .fill((complete ? Theme.kelp : Theme.teal).opacity(0.45))
                .clipShape(Circle())
            Circle().stroke(complete ? Theme.kelp : Theme.ocean, lineWidth: 3)
            Text("\(Int(progress * 100))%")
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.textPrimary)
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .contentTransition(.numericText(value: progress))
            BubbleBurst(trigger: celebrate)
        }
        .frame(width: min(ringSize, 130), height: min(ringSize, 130))
    }
}

/// Water with a gently curved surface. It moves only when the level changes.
private struct WaterFill: Shape {
    var level: Double

    var animatableData: Double {
        get { level }
        set { level = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard level > 0 else { return path }
        // The ripple flattens out when empty or full, and travels as the level rises.
        let fill = CGFloat(min(level, 1))
        let amplitude = rect.height * 0.05 * CGFloat(sin(Double(fill) * Double.pi))
        let surface = rect.maxY - rect.height * fill
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        for x in stride(from: rect.minX, through: rect.maxX, by: 2) {
            let angle = Double((x - rect.minX) / rect.width) * 2 * Double.pi + level * 18
            path.addLine(to: CGPoint(x: x, y: surface + CGFloat(sin(angle)) * amplitude))
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Section View

struct ChecklistSectionView: View {
    let section: ChecklistSection
    @Binding var items: [ChecklistItem]
    let onDelete: (Int) -> Void

    var body: some View {
        Section {
            ForEach($items) { $item in
                ChecklistItemRow(item: $item, tint: section.color)
            }
            .onDelete { indexSet in
                indexSet.sorted(by: >).forEach { onDelete($0) }
            }
        } header: {
            HStack(spacing: Theme.Spacing.sm) {
                IconBadge(systemName: section.icon, color: section.color, size: 22)
                    .accessibilityHidden(true)
                Text(section.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("\(items.filter(\.isChecked).count)/\(items.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
                    .monospacedDigit()
            }
            .textCase(nil)
            .padding(.bottom, 2)
        }
        .listRowBackground(Theme.surface)
    }
}

// MARK: - Item Row

struct ChecklistItemRow: View {
    @Binding var item: ChecklistItem
    var tint: Color = Theme.ocean

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                item.isChecked.toggle()
            }
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(item.isChecked ? tint : Theme.textTertiary)
                    .contentTransition(.symbolEffect(.replace))
                    .symbolEffect(.bounce, value: item.isChecked)

                Text(item.title)
                    .foregroundStyle(item.isChecked ? Theme.textTertiary : Theme.textPrimary)
                    .strikethrough(item.isChecked, color: Theme.textTertiary)

                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: item.isChecked)
        .accessibilityValue(item.isChecked ? "Packed" : "Not packed")
    }
}

// MARK: - Add Item Sheet

struct AddChecklistItemView: View {
    @ObservedObject var viewModel: ChecklistViewModel
    @Binding var selectedSection: ChecklistSection
    @Binding var newItemTitle: String
    @Binding var isPresented: Bool
    @FocusState private var isFocused: Bool

    private var trimmed: String { newItemTitle.trimmingCharacters(in: .whitespaces) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    TextField("e.g. Underwater camera", text: $newItemTitle)
                        .focused($isFocused)
                        .submitLabel(.done)
                        .onSubmit(add)
                }

                Section("Category") {
                    Picker("Category", selection: $selectedSection) {
                        ForEach(ChecklistSection.allCases, id: \.self) { section in
                            Label {
                                Text(section.title)
                            } icon: {
                                IconBadge(systemName: section.icon, color: section.color, size: 26)
                            }
                            .tag(section)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
            }
            .navigationTitle("New Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        newItemTitle = ""
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add", action: add)
                        .fontWeight(.semibold)
                        .disabled(trimmed.isEmpty)
                }
            }
            .onAppear { isFocused = true }
        }
        .tint(Theme.ocean)
    }

    private func add() {
        guard !trimmed.isEmpty else { return }
        viewModel.addItem(to: selectedSection, title: trimmed)
        newItemTitle = ""
        isPresented = false
    }
}

struct ChecklistScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack { ChecklistScreen() }
            .environmentObject(DivePlannerViewModel(weatherViewModel: WeatherViewModel()))
    }
}
