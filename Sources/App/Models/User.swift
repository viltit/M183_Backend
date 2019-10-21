import Foundation
import FluentMySQL
import Vapor
import Authentication

final class User: Model {

    enum Role : String, Codable, ReflectionDecodable {
        // i do not get why this is needed. We have to return two distinct instances in order for this enum to be codable
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
    var password: String
    var avatar: String?
    var role: Role

    // add parent-child relationship between User and Patient
    var patients: Children<User, Patient> {
        return children(\.docID)
    }

    init(firstName: String, lastName: String, email: String, password: String, role: Role, avatar: String? = nil) {
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.password = password
        self.role = role
        self.avatar = avatar
    }

    // converts a User instance to its public form (ie., without password in our case)
    func toPublic() -> User.Public {
        return User.Public(id: id, firstName: firstName, lastName: lastName, email: email, role: role)
    }

    // The public subclass is used because we do not want to return the whole User (including the password !) to
    // a client: The public subclass represents the public view of a User
    final class Public : Codable, Content {
        var id: Int?
        var firstName: String
        var lastName: String
        var email: String
        var role: Role

        init(id: Int?, firstName: String, lastName: String, email: String, role: Role) {
            self.firstName = firstName
            self.lastName = lastName
            self.email = email
            self.role = role
        }
    }
}

// conform to migrations for automated table creation:
extension User : MySQLMigration {
    /* Configure the users email to be unique */
    static func prepare(on conn: MySQLConnection) -> Future<Void> {
        return MySQLDatabase.create(User.self, on: conn) { builder in
            try addProperties(to: builder)  // add all attributes from User
            builder.unique(on: \.email)     // add unique-constraint to User.email
        }
    }
}

// conform to Content for encoding and decoding this Model from and to JSON
extension User : Content { }

// conform to Parameter to allow getting a User from POST-Parameters
extension User : Parameter { }

// conform to Authenticatibale  and tell Vapor whit keypath we use as "username"
extension User : BasicAuthenticatable {
    static let usernameKey: UsernameKey = \User.email
    static let passwordKey: PasswordKey = \User.password
}

// Allow authentication of a User via a Token:
extension User : TokenAuthenticatable {
    typealias TokenType = Token
}

// Tokens are not good for the webclient - storing it in Local Storage is a security risk -
// --> The following extensions allow authentication via Sessions
extension User : PasswordAuthenticatable { }
extension User : SessionAuthenticatable { }

// helper method to reduce nesting: Allows to call .toPublic on a Future<User>
extension Future where T: User {
    func toPublic() -> Future<User.Public> {
        return self.map(to: User.Public.self) { user in
            return user.toPublic()
        }
    }
}