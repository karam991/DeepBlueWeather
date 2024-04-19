//
//  Checklist.swift
//  DeepBlueWeather
//
//  Created by Abdulkarim Alnaser on 12.04.24.
//

// Checklist.swift
import Foundation


struct ChecklistItem:Codable, Identifiable {
    var id = UUID()
    let title: String
    var isChecked: Bool
}
