/*
    Because all routes are protected via a Bearer Token (except the Login which is protected by password),
    we now are unable to use the api on a fresh database.

    -> This struct creates a new Admin User on Migrations. In a production environment, the password should NOT
    be included in the code but by an environment variable or an App parameter
*/

import Vapor
import FluentMySQL
import Authentication

struct AdminUser : Migration {

    typealias Database = MySQLDatabase

    static func prepare(on connection: MySQLConnection) -> Future<Void> {

        // no transaction needed here because this code will only run once on a new database
        let password = try? BCrypt.hash("I am visible")
        guard let hashedPW = password else {
            fatalError("Failed to create admin user")
        }
        let user = User(
            firstName: "admin",
            lastName: "admin",
            email: "admin@admin.ch",
            password: hashedPW,
            role: .admin
        )
        return user.save(on: connection).transform(to: ())
    }

    // just needed by the Migrations Protocol, not used by us:
    static func revert(on connection: MySQLConnection) -> Future<Void> {
        return .done(on: connection)
    }
}