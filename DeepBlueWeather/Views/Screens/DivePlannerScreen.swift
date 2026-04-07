//
//  DivePlannerScreen.swift
//  DeepBlueWeather
//
//  Created by Abdulkarim Alnaser on 26.02.24.
//

import SwiftUI

struct DivePlannerScreen: View {
    @EnvironmentObject var viewModel: DivePlannerViewModel

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color("OceanBlue").opacity(0.1), Color("SoftTeal").opacity(0.05)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack {
                if viewModel.divePlans.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "figure.open.water.swim")
                            .font(.system(size: 60))
                            .foregroundColor(Color("OceanBlue").opacity(0.3))
                        Text("No dive plans yet")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("Tap + to plan your first dive")
                            .font(.subheadline)
                            .foregroundColor(.gray.opacity(0.7))
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.divePlans) { plan in
                            DivePlanCard(plan: plan)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { viewModel.deleteDivePlan(at: $0) }
                        }
                    }
                    .listStyle(.plain)
                    .background(Color.clear)
                }

                Button(action: {
                    viewModel.showingDivePlannerSheet = true
                }) {
                    HStack {
                        Image(systemName: "plus")
                            .fontWeight(.bold)
                        Text("Plan a Dive")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("OceanBlue"))
                    .cornerRadius(14)
                    .shadow(color: Color("OceanBlue").opacity(0.4), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
                .sheet(isPresented: $viewModel.showingDivePlannerSheet) {
                    DivePlannerSheetView(divePlannerViewModel: viewModel)
                }
            }
        }
        .navigationBarTitle("Dive Planner", displayMode: .large)
        .onAppear {
            viewModel.readDivePlans()
        }
    }
}

struct DivePlanCard: View {
    var plan: DivePlan

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.location)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color("OceanBlue"))

                    if let date = DateFormatter.firestoreDate.date(from: plan.date) ?? DateFormatter.iso8601WithSeconds.date(from: plan.date) ?? DateFormatter.iso8601Full.date(from: plan.date) {
                        Text(DateFormatter.readableDate.string(from: date))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }

                Spacer()

                Image(systemName: plan.nightDive ? "moon.stars.fill" : "sun.max.fill")
                    .font(.title2)
                    .foregroundColor(plan.nightDive ? Color("Coral") : Color("SeaGreen"))
            }

            Divider()

            // Stats row
            HStack(spacing: 0) {
                DiveStat(icon: "arrow.down.to.line", value: "\(plan.depth)m", label: "Depth", color: Color("OceanBlue"))
                Spacer()
                DiveStat(icon: "clock", value: "\(plan.duration)min", label: "Duration", color: Color("SoftTeal"))
                Spacer()
                DiveStat(icon: plan.deepDive ? "chevron.down.2" : "minus", value: plan.deepDive ? "Deep" : "Shallow", label: "Type", color: Color("SeaGreen"))
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 3)
    }
}

struct DiveStat: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 16))
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }
}
