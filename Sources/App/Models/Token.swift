/*
    Define a Model for Token Autentication
    The token will be stored in the database like any other model
*/

import Foundation
import Vapor
import FluentMySQL
import Authentication

final class Token : Codable, Content, MySQLModel {

    var id: Int?
    var token: String
    var userID: User.ID   // foreign key

    init(token: String, userID: User.ID) {
        self.token = token
        self.userID = userID
    }

    // generate a token for a given User:
    static func generate(for user: User) throws -> Token {

        // the access token will consist of 16 random bytes
        let random = try CryptoRandom().generateData(count: 16)
        return try Token (
            token: random.base64EncodedString(),
            userID: user.requireID())
    }
}

extension Token : Migration {
    static func prepare(on connection: MySQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            // add foreign key restraint to Users id
            builder.reference(from: \.userID, to: \User.id)
        }
    }
}

// conform to Authentication Token Protocol
extension Token : Authentication.Token {

    typealias UserType = User
    static let userIDKey: UserIDKey = \Token.userID
}

// use bearer Autentication:
extension Token : BearerAuthenticatable {
    static let tokenKey: TokenKey = \Token.token
}



