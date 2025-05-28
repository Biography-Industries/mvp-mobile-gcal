//
//  SingleMessageView.swift
//  GcalDemo
//
//  Created by Hsia Lu wu on 5/28/25.
//

import SwiftUI

struct SingleMessageView: View {
    let message: Message
    
    var body: some View {
        switch message.content {
        case .text(let text):
            HStack(alignment: .bottom, spacing: 10) {
                if !message.isUser {
                    // TODO: Donna image
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 25, height: 25, alignment: .center)
                        .cornerRadius(12.5)
                } else {
                    Spacer()
                }
                
                MessageBubble(message: text, isUser: message.isUser)
                
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
    }
}

#Preview {
    SingleMessageView(message: Message(id: UUID(), content: .text("I want to go hiking on Friday with Amy and Belle"), sender: .user, isUser: true))
}
