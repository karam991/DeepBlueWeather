//
//  DiveLogSheet.swift
//  DeepBlueWeather
//
//  Log what actually happened on a dive: depth, time, temperature,
//  visibility, rating, buddy, notes and photos.
//

import SwiftUI
import PhotosUI

struct DiveLogSheet: View {
    let plan: DivePlan
    var waterTemperatureHint: Double?

    @EnvironmentObject private var viewModel: DivePlannerViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var depth: Int
    @State private var duration: Int
    @State private var waterTemp: Double
    @State private var visibility: Int
    @State private var rating: Int
    @State private var buddy: String
    @State private var notes: String
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var photos: [URL] = []
    @State private var isImporting = false

    init(plan: DivePlan, waterTemperatureHint: Double? = nil) {
        self.plan = plan
        self.waterTemperatureHint = waterTemperatureHint
        let log = plan.log
        _depth = State(initialValue: log?.actualDepth ?? plan.depth)
        _duration = State(initialValue: log?.actualDuration ?? plan.duration)
        _waterTemp = State(initialValue: (log?.waterTemperature ?? waterTemperatureHint ?? 20).rounded())
        _visibility = State(initialValue: log?.visibility ?? 10)
        _rating = State(initialValue: log?.rating ?? 4)
        _buddy = State(initialValue: log?.buddy ?? "")
        _notes = State(initialValue: log?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    ratingCard
                    FormSection(title: "Dive profile", icon: "gauge.with.dots.needle.67percent", color: Theme.ocean) {
                        VStack(spacing: 0) {
                            row("Max depth", value: $depth, range: 1...60, step: 1, unit: "m")
                            Divider()
                            row("Bottom time", value: $duration, range: 5...240, step: 1, unit: "min")
                            Divider()
                            Stepper(value: $waterTemp, in: 0...35, step: 1) {
                                HStack {
                                    Text("Water temperature")
                                    Spacer()
                                    Text("\(Int(waterTemp)) °C").font(.body.weight(.semibold)).monospacedDigit().foregroundStyle(Theme.ocean)
                                }
                            }
                            .padding(.vertical, 10)
                            Divider()
                            row("Visibility", value: $visibility, range: 1...60, step: 1, unit: "m")
                        }
                        .foregroundStyle(Theme.textPrimary)
                    }
                    FormSection(title: "Buddy & notes", icon: "person.2.fill", color: Theme.teal) {
                        TextField("Dive buddy", text: $buddy)
                            .textContentType(.name)
                            .padding(Theme.Spacing.md)
                            .background(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous).fill(Theme.surfaceRaised))
                        TextField("What did you see? Turtles, wrecks, currents…", text: $notes, axis: .vertical)
                            .lineLimit(3...8)
                            .padding(Theme.Spacing.md)
                            .background(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous).fill(Theme.surfaceRaised))
                    }
                    photosCard
                }
                .padding(Theme.Spacing.lg)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle(plan.log == nil ? "Log Dive" : "Edit Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).fontWeight(.semibold)
                }
            }
            .onAppear { if let id = plan.id { photos = DivePhotoStore.photoURLs(for: id) } }
            .onChange(of: pickerItems) { _, items in importPhotos(items) }
        }
        .tint(Theme.ocean)
    }

    // MARK: Rating

    private var ratingCard: some View {
        VStack(spacing: Theme.Spacing.md) {
            Text("How was the dive?")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            HStack(spacing: Theme.Spacing.md) {
                ForEach(1...5, id: \.self) { star in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { rating = star }
                    } label: {
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .font(.system(size: 30))
                            .foregroundStyle(star <= rating ? Theme.sand : Theme.textTertiary)
                            .scaleEffect(star == rating ? 1.15 : 1)
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(star) stars")
                }
            }
            .sensoryFeedback(.selection, trigger: rating)
        }
        .frame(maxWidth: .infinity)
        .card()
    }

    // MARK: Photos

    private var photosCard: some View {
        FormSection(title: "Photos", icon: "camera.fill", color: Theme.coral) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: Theme.Spacing.sm)], spacing: Theme.Spacing.sm) {
                ForEach(photos, id: \.self) { url in
                    LocalPhoto(url: url)
                        .frame(height: 90)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
                        .overlay(alignment: .topTrailing) {
                            Button {
                                withAnimation { DivePhotoStore.delete(url); photos.removeAll { $0 == url } }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, .black.opacity(0.5))
                                    .font(.title3)
                            }
                            .padding(4)
                        }
                        .transition(.scale.combined(with: .opacity))
                }
                PhotosPicker(selection: $pickerItems, maxSelectionCount: 10, matching: .images) {
                    VStack(spacing: 6) {
                        if isImporting { ProgressView() } else { Image(systemName: "plus").font(.title2) }
                        Text("Add").font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(Theme.ocean)
                    .frame(maxWidth: .infinity, minHeight: 90)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                            .strokeBorder(Theme.ocean.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    )
                }
            }
            Text("Photos are stored on this iPhone.")
                .font(.caption)
                .foregroundStyle(Theme.textTertiary)
        }
    }

    private func row(_ title: String, value: Binding<Int>, range: ClosedRange<Int>, step: Int, unit: String) -> some View {
        Stepper(value: value, in: range, step: step) {
            HStack {
                Text(title)
                Spacer()
                Text("\(value.wrappedValue) \(unit)").font(.body.weight(.semibold)).monospacedDigit().foregroundStyle(Theme.ocean)
            }
        }
        .padding(.vertical, 10)
    }

    private func importPhotos(_ items: [PhotosPickerItem]) {
        guard let id = plan.id, !items.isEmpty else { return }
        isImporting = true
        Task {
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data),
                   let url = DivePhotoStore.save(image, for: id) {
                    await MainActor.run { withAnimation { photos.append(url) } }
                }
            }
            await MainActor.run {
                pickerItems = []
                isImporting = false
            }
        }
    }

    private func save() {
        let log = DiveLog(
            actualDepth: depth,
            actualDuration: duration,
            waterTemperature: waterTemp,
            visibility: visibility,
            rating: rating,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            buddy: buddy.trimmingCharacters(in: .whitespaces).isEmpty ? nil : buddy.trimmingCharacters(in: .whitespaces),
            loggedAt: plan.log?.loggedAt ?? Date()
        )
        viewModel.saveLog(log, for: plan)
        dismiss()
    }
}

/// Loads a JPEG from disk off the main thread.
struct LocalPhoto: View {
    let url: URL
    @State private var image: UIImage?

    var body: some View {
        Theme.surfaceRaised
            .overlay {
                if let image {
                    Image(uiImage: image).resizable().scaledToFill()
                } else {
                    ProgressView()
                }
            }
            .clipped()
            .task(id: url) {
                let loaded = await Task.detached { UIImage(contentsOfFile: url.path)?.preparingThumbnail(of: CGSize(width: 400, height: 400)) }.value
                image = loaded
            }
    }
}
