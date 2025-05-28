//
//  MainChatView.swift
//  GcalDemo
//
//  Created by Hsia Lu wu on 5/28/25.
//

import SwiftUI

struct MainChatView: View {
    // MARK: Properties
    @StateObject private var chatViewModel = ChatViewModel()
    
    var body: some View {
        VStack {
            // Main chat
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(chatViewModel.messages) { message in
                        SingleMessageView(message: message)
                    }
                }
            }
            
            Divider()
                        
            // Input query field
            HStack {
                TextField("Ask Donna...", text: $chatViewModel.inputText)
                    .frame(maxWidth: .infinity)
                
                Button {
                    // TODO: action (send message)
                    chatViewModel.sendMessage()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
        }
    }
}

#Preview {
    MainChatView()
}
