import Foundation
import FluentMySQL


final class User : Model, Migration {

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