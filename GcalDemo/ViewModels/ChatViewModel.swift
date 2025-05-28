//
//  ChatViewModel.swift
//  GcalDemo
//
//  Created by Hsia Lu wu on 5/28/25.
//

import Foundation
import SwiftUI
import Combine

class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var inputText: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    func sendMessage() {
        guard !inputText.isEmpty else { return }
        
        // append user message
        let userMessage = Message(id: UUID(), content: .text(inputText), sender: .user, isUser: true)
        messages.append(userMessage)
        
        let query = inputText
        inputText = "" // reset input
        
        // LLM call
        // TODO: replace with real API call later on
        simulateLLMResponse(for: query)
    }
    
    private func simulateLLMResponse(for query: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            // convert response to MessageContent
            let responseContent = self.convertResponse(from: query)
            let responseMessage = Message(id: UUID(), content: responseContent, sender: .donna, isUser: false)
            self.messages.append(responseMessage)
        }
    }
    
    private func convertResponse(from query: String) -> MessageContent {
        // response logic
        // TODO: replace with real JSON decoder
        return .text("Fake LLM response to query: \(query)")
    }
}
