import Foundation
import Vapor


// This extensions allows us to get a User from a requests session
extension Request {
    func getUserFromSession() throws -> Future<User> {
        if try !self.hasSession() {
            throw Abort(.unauthorized)
        }
        guard let userID = try self.session()["userID"], let id = Int(userID) else {
            print(try self.session()["userID"])
            throw Abort(.unauthorized)
        }
        return try self.transaction(on: .mysql) { connection in
            return User.find(id, on: connection).unwrap(or: Abort(.notFound))
        }
    }
}