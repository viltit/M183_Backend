import Foundation
import Vapor
import Fluent

// Defines all routes to the User
struct UserController: RouteCollection {

    // register routes
    func boot(router: Router) throws {
        router.get("api/users", use: getAll)
        router.get("api/users/patients", User.parameter, use: getPatients)
        router.post("api/users/find", use: get)
        router.post("api/users/create", use: create)
        router.put("api/users", User.parameter, use: update)
        router.delete("api/users", use: delete)
    }

    // Decodable for post-request with user id
    struct IDDecodable : Decodable {
        let id: Int
    }

    // CRUD-Operations
    func getAll(_ request: Request) throws -> Future<[User]> {
        return try request.transaction(on: .mysql) { connection in
            return User.query(on: connection).all()
        }
    }


    func getPatients(_ request: Request) throws -> Future<[Patient]> {
        return try request.transaction(on: .mysql) { connection in
            return try request
                    .parameters
                    .next(User.self)
                    .flatMap(to: [Patient].self)
            {
                user in
                return try user.patients.query(on: connection).all()
            }
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
                        return user.save(on: connection)
                    }
        }
    }

    func update(_ request: Request) throws -> Future<User> {
        return try request.transaction(on: .mysql) { connection in
            return try flatMap(
                    to: User.self,
                    request.parameters.next(User.self),   // get existing User from the id delivered as GET-Parameter
                    request.content.decode(User.self)) {  // get updated User from request JSON

                user, newUser in
                user.firstName = newUser.firstName
                user.lastName = newUser.lastName
                user.email = newUser.email
                user.role = newUser.role
                return user.save(on: connection)
            }
        }
    }

    func delete(_ request: Request) throws -> Future<HTTPStatus> {
        return try request.transaction(on: .mysql) { connection in
            return try request
                    .content
                    .decode(User.self)                     // TODO: Only send users id
                    .flatMap(to: HTTPStatus.self) { user in
                        return try user.delete(on: connection)
                                .transform(to: .noContent)
                    }
        }
    }
}