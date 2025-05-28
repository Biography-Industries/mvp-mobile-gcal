//
//  ContactsView.swift
//  GcalDemo
//
//  Created by Hsia Lu wu on 5/28/25.
//

import SwiftUI
import Contacts

struct ContactsView: View {
    // MARK: Properties
    @State private var contacts: [ContactItem] = []
    @State private var selectedContacts: Set<ContactItem> = []
    @State private var isLoading = true
    @State private var fetchError: String?
    @State private var navigateToChat = false
    
    var body: some View {
        NavigationStack {
            Group {
                VStack {
                    Text("Select Contacts to be Prioritized")
                        .foregroundStyle(.black)
                        .bold()
                        .padding(.horizontal)
                    
                    if isLoading {
                        ProgressView("Loading contacts...")
                    } else if let error = fetchError {
                        Text(error)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                    } else {
                        List {
                            ForEach(contacts) { contact in
                                ContactRowView(contact: contact, isSelected: selectedContacts.contains(contact)) {
                                    toggleSelection(for: contact)
                                }
                            }
                        }
                    }
                    
                    // finish selecting button
                    Button {
                        // navigate to the chat screen
                        navigateToChat = true
                    } label: {
                        Text("Finish Selecting")
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.horizontal, 20)
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToChat, destination: {
                MainChatView()
            })
            .task {
                await fetchAllContacts()
            }
        }
    }
}

// MARK: Functions
extension ContactsView {
    func fetchAllContacts() async { // run this in background async
        // get access to the contacts store
        let store = CNContactStore()
        
        // specify what data keys we want to fetch
        let keys = [CNContactGivenNameKey, CNContactPhoneNumbersKey] as [CNKeyDescriptor]
        
        // create fetch request
        let fetchRequest = CNContactFetchRequest(keysToFetch: keys)
        
        // call method to fetch all contacts
        do {
            var fetchedContacts: [ContactItem] = []
            
            try store.enumerateContacts(with: fetchRequest) { contact, _ in
                let numbers = contact.phoneNumbers.map { $0.value.stringValue }
                fetchedContacts.append(ContactItem(givenName: contact.givenName, phoneNumbers: numbers))
                print("fetched contact: \(contact.givenName)")
            }
            
            await MainActor.run {
                contacts = fetchedContacts
                isLoading = false
            }
        } catch {
            await MainActor.run {
                fetchError = "Error in fetchAllContacts: Failed to load contacts. Enable access in Settings > Privacy > Contacts."
                isLoading = false
            }
        }
    }
    
    private func toggleSelection(for contact: ContactItem) {
        if selectedContacts.contains(contact) {
            selectedContacts.remove(contact)
        } else {
            selectedContacts.insert(contact)
        }
    }
}

#Preview {
    ContactsView()
}
