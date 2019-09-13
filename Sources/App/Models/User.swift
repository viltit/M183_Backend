import Foundation
import FluentMySQL
import Vapor

final class User : Model {

    // conform to Model. We could inherit from MySQL-Model to avoid this code, but I prefer to be
    // explicit here
    typealias ID = Int
    typealias Database = MySQLDatabase
    static let idKey: IDKey = \.id

    var id: Int?
    var firstName: String
    var lastName: String
    var email: String
    var username: String

    init(firstName: String, lastName: String, email: String, username: String) {
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.username = username
    }
}

// conform to migrations for automated table creation:
extension User : Migration { }

// conform to Content for encoding and decoding this Model from and to JSON
extension User : Content { }

// conform to Parameter to allow getting a User from