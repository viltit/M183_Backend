
import Foundation
import FluentMySQL
import Vapor

final class PatientEntry : Model {

    typealias Database = MySQLDatabase
    typealias ID = Int
    static let idKey: IDKey = \.id

    var id: Int?
    var patientID: Patient.ID
    var date: Date
    var short: String
    var long: String


    init(date: Date, short: String, long: String, patientID: Int) {
        self.date = date
        self.short = short
        self.long = long
        self.patientID = patientID
    }
}

// conform to migrations for automated table creation:
extension PatientEntry : Migration { }

// conform to Content for encoding and decoding this Model from and to JSON
extension PatientEntry : Content { }

// conform to Parameter to allow getting a User from POST-Parameters
extension PatientEntry : Parameter { }