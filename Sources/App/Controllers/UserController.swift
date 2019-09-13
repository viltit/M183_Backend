import Foundation
import Vapor
import Fluent

// Defines all routes to the User
struct UserController : RouteCollection {

    // register routes
    func boot(router: Router) throws {
        router.get("api/users", use: getAll)
        router.post("api/users/find", use: get)
        router.post("api/users/create", use: create)
    }

    // Decodable for post-request with user id
    struct IDDecodable : Decodable {
        let id: Int
    }

    func getAll(_ request: Request) throws -> Future<[User]> {
        return try request.transaction(on: .mysql) { connection in
            return User.query(on: connection).all()
        }
    }

    func get(_ request: Request) throws -> Future<User> {
         return try request.transaction(on: .mysql) { connection in
            return try request
                    .content
                    .decode(IDDecodable.self)
                    .flatMap(to: User.self) { idDecodable in
                        return try User.find(idDecodable.id, on: connection).map { user in
                            guard let user = user else {
                                throw Abort(.noContent, reason: "No user with id \(idDecodable.id)")
                            }
                            return user
                        }
            }
        }
    }

    func create(_ request: Request) throws -> Future<User> {
        return try request.transaction(on: .mysql) { connection in
            return try request
                    .content
                    .decode(User.self)
                    .flatMap(to: User.self) { user in
                        return user.save(on: request)
                    }
        }
    }




}