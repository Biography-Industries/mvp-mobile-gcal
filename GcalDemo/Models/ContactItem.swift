//
//  ContactItem.swift
//  GcalDemo
//
//  Created by Hsia Lu wu on 5/28/25.
//

import Foundation

struct ContactItem: Identifiable, Hashable {
    let id = UUID()
    let givenName: String
    let phoneNumbers: [String]
}
