//
//  SearchBarView.swift
//  DeepBlueWeather
//
//  Created by Abdulkarim Alnaser on 16.04.24.
//

import SwiftUI

struct SearchBarView: View {
    @Binding var text: String
    @Binding var isSearching: Bool

    var body: some View {
        HStack {
            TextField("Search", text: $text)
                .padding(.leading, 24)
        }
        .padding()
        .background(Color(.systemGray5))
        .cornerRadius(8)
        .padding(.horizontal)
        .onTapGesture {
            isSearching = true
        }
    }
}

struct SearchBarView_Previews: PreviewProvider {
    static var previews: some View {
        SearchBarView(text: .constant(""), isSearching: .constant(false))
            
    }
}

