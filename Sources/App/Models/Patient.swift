
import Foundation
import FluentMySQL
import Vapor

final class Patient : Model {

    typealias Database = MySQLDatabase
    typealias ID = Int
    static let idKey: IDKey = \.id

    var id: Int?
    var docID: Doctor.ID
    var firstName: String
    var lastName: String
    var email: String
    var username: String

    // add parent-child-realtion to PatientEntry
    var entries: Children<Patient, PatientEntry> {
        return children(\.patientID)
    }

    init(firstName: String, lastName: String, email: String, username: String, docID: Doctor.ID) {
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.username = username
        self.docID = docID
    }
}

// conform to migrations for automated table creation:
extension Patient : Migration { }

// conform to Content for encoding and decoding this Model from and to JSON
extension Patient : Content { }

// conform to Parameter to allow getting a User from POST-Parameters
extension Patient : Parameter { }