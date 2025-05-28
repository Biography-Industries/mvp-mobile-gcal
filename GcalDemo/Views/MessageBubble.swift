//
//  MessageBubble.swift
//  GcalDemo
//
//  Created by Hsia Lu wu on 5/28/25.
//

import Foundation
import SwiftUI

struct MessageBubble: View {
    var message: String
    var isUser: Bool
        
    var body: some View {
        Text(message)
            .padding(10)
            .foregroundColor(isUser ? Color.white : Color.black)
            .background(isUser ? Color.blue : Color(UIColor.systemGray6 ))
            .cornerRadius(10)
    }
}

