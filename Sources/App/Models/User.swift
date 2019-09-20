import Foundation
import FluentMySQL
import Vapor

final class User: Model {

    enum Role : String, Codable, ReflectionDecodable {

        // i do not get why this is needed. We have to return two distinct instances
        static func reflectDecoded() throws -> (User.Role, User.Role) {
            return (.doctor, .nurse)
        }

        case doctor = "doctor"
        case nurse = "nurse"
        case admin = "admin"
    }

    /* We could add a custom key mapping between table attributes and class attributes here,
    but this is not needed for now
    enum CodingKeys : String, CodingKey {
    }
    */

    // conform to Model. We could inherit from MySQL-Model to avoid this code, but I prefer to be
    // explicit here
    typealias ID = Int
    typealias Database = MySQLDatabase
    static let idKey: IDKey = \.id

    var id: Int?
    var firstName: String
    var lastName: String
    var email: String
    var role: Role

    // add parent-child relationship between User and Patient
    var patients: Children<User, Patient> {
        return children(\.docID)
    }

    init(firstName: String, lastName: String, email: String, role: Role) {
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.role = role
    }
}

// conform to migrations for automated table creation:
extension User : MySQLMigration {
    /* We could configure the table here, but the standard configutation is enough for now
    static func prepare(on conn: MySQLConnection) -> Future<Void> {
        return MySQLDatabase.create(User.self, on: conn) { builder in
        }
    }
    */
}

// conform to Content for encoding and decoding this Model from and to JSON
extension User : Content { }

// conform to Parameter to allow getting a User from POST-Parameters
extension User : Parameter { }