//
//  ChecklistSheetView.swift
//  DeepBlueWeather
//
//  Created by Abdulkarim Alnaser on 20.03.24.
//

import SwiftUI

struct ChecklistSheetView: View {
    var body: some View {
        VStack {
            Text("Checklists")
            Button(action: {
                
                
                
            }) {
                Image(systemName: "plus")
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .clipShape(Circle())
            .padding()
        }
    }
}

#Preview {
    ChecklistSheetView()
}
