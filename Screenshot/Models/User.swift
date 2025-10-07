//
//  User.swift
//  Screenshot
//
//  Created by Bhawanjot Singh Kooner on 2025-10-04.
//

import Foundation
import SwiftData

@Model
class User {
    var id: UUID
    var name: String
    var email: String
    var dateCreated: Date
    var isOnboardingComplete: Bool
    
    init(name: String, email: String) {
        self.id = UUID()
        self.name = name
        self.email = email
        self.dateCreated = Date()
        self.isOnboardingComplete = false
    }
}
