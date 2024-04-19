//
//  FirebaseManager.swift
//  DeepBlueWeather
//
//  Created by Abdulkarim Alnaser on 12.04.24.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class FirebaseManager {
    static let shared = FirebaseManager()
    
    let authenticator = Auth.auth()
    let fireStore = Firestore.firestore()
    
    var userId: String? {
        authenticator.currentUser?.uid
    }
}
