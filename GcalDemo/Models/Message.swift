//
//  Message.swift
//  GcalDemo
//
//  Created by Hsia Lu wu on 5/28/25.
//

import Foundation

struct Message: Identifiable {
    var id: UUID
    var content: MessageContent
    var sender: Sender
    var isUser: Bool
    
    static let dummyMessages: [Message] = [
        Message(id: UUID(), content: .text("I want to go hiking on Friday with Amy and Belle"), sender: .user, isUser: true),
        Message(id: UUID(), content: .text("Sounds fun! Would you like me to send an invite?"), sender: .donna, isUser: false),
        Message(id: UUID(), content: .text("Yes please"), sender: .user, isUser: true),
        Message(id: UUID(), content: .text("Perfect! Here is the detail."), sender: .donna, isUser: false)
    ]
}

enum Sender {
    case user
    case donna
}

enum MessageContent {
    case text(String)
//    case table(TableData)
//    case profile(ProfileData)
}

// MARK: will be used later
struct TableData {
    let headers: [String]
    let rows: [[String]]
}

struct ProfileData {
    let name: String
    let age: Int
    let avatarURL: URL
    let bio: String
}
