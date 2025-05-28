//
//  ContactRowView.swift
//  GcalDemo
//
//  Created by Hsia Lu wu on 5/28/25.
//

import SwiftUI

struct ContactRowView: View {
    let contact: ContactItem
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(contact.givenName)
                    .font(.headline)
                
                ForEach(contact.phoneNumbers, id: \.self) { number in
                    Text(number)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                onToggle()
            } label: {
                if isSelected {
                    Label("Deselect", systemImage: "xmark.circle")
                } else {
                    Label("Prioritize", systemImage: "star")
                }
            }
            .tint(isSelected ? .red : .green)
        }
    }
    
    
}

func testToggle() -> Void {
    
}

#Preview {
    ContactRowView(contact: ContactItem(givenName: "Amy", phoneNumbers: ["123456789"]), isSelected: true, onToggle: testToggle)
}
