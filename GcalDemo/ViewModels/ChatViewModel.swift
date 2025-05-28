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
    var isThinking = false
    
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
    
    // MARK: Simulation for demo purpose
    func sendDemoMessage() {
        guard !inputText.isEmpty else { return }
        
        // append user message
        let userMessage = Message(id: UUID(), content: .text(inputText), sender: .user, isUser: true)
        messages.append(userMessage)
        
        let query = inputText
        inputText = "" // reset input
        
        // LLM call
        // TODO: replace with real API call later on
        simulatedResponse(from: query) { responses in
            for response in responses {
                let responseMessage = Message(id: UUID(), content: response, sender: .donna, isUser: false)
                DispatchQueue.main.async {
                    self.messages.append(responseMessage)
                }
            }
        }
    }
    
    private func simulatedResponse(from query: String, completion: @escaping ([MessageContent]) -> Void) {
        isThinking = true
        let thinkingMessage = Message(id: UUID(), content: .text("Searching..."), sender: .donna, isUser: false)
        messages.append(thinkingMessage)
        
        var result: [MessageContent] = []
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // convert response to MessageContent
            self.isThinking = false
            self.messages.removeAll(where: { $0.content.textValue == "Searching..." })
            
            switch query.lowercased() {
                case "i want to go hiking friday afternoon with 5 people":
                print("matched case: I want to go hiking Friday afternoon with 5 people")
                result =  [.text("I think Sungjoo, Anmay, Julia, Subham, and Dez might be down for the idea!"), .profile(ProfileData(name: "Sungjoo", location: "Boston", phoneNumber: "123")), .profile(ProfileData(name: "Anmay", location: "Boston", phoneNumber: "456")), .profile(ProfileData(name: "Julia", location: "Boston", phoneNumber: "789")), .profile(ProfileData(name: "Subham", location: "Boston", phoneNumber: "134")), .profile(ProfileData(name: "Dez", location: "Boston", phoneNumber: "235"))]
                
                case "not sungjoo and anmay":
                print("matched case: Not Sungjoo and Anmay")
                result =  [.text("Okay, how about Sol and Ethan instead?"), .profile(ProfileData(name: "Julia", location: "Boston", phoneNumber: "789")), .profile(ProfileData(name: "Subham", location: "Boston", phoneNumber: "134")), .profile(ProfileData(name: "Dez", location: "Boston", phoneNumber: "235")), .profile(ProfileData(name: "Sol", location: "Boston", phoneNumber: "123")), .profile(ProfileData(name: "Ethan", location: "Boston", phoneNumber: "456"))]
                
                case "that sounds good, can you connect with them?":
                print("matched case: That sounds good, can you connect with them?")
                result = [.text("Sounds good! Checking when they are free. I'll get back to you in a bit."), .text("Looks like 2:00pm works best for everyone (and you), and unfortunately Subham couldn't make it. Have fun!")]
                
                default:
                print("default")
                    result = [.text("Sorry, I don't have information about that yet.")]
            }
            
            completion(result)
        }
    }
}
