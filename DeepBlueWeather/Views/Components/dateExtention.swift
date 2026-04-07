//
//  dateExtention.swift
//  DeepBlueWeather
//
//  Created by Abdulkarim Alnaser on 26.04.24.
//

import Foundation
extension Date {
    func formatted(style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = style
        return formatter.string(from: self)
    }
}
