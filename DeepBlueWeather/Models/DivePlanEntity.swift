//
//  DivePlanEntity.swift
//  DeepBlueWeather
//
//  Created by Abdulkarim Alnaser on 11.04.24.
//

import Foundation
import FirebaseFirestoreSwift


struct DivePlan: Codable, Identifiable {
    @DocumentID var id : String?
    var userId : String
    var location: String
    var date: String
    var depth: Int
    var duration: Int
    var deepDive: Bool
    var nightDive: Bool
}
