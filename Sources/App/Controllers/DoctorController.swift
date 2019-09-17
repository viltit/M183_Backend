import Foundation
import Vapor
import Fluent

// Defines all routes to the User
struct DoctorController: RouteCollection {

    // register routes
    func boot(router: Router) throws {
        router.get("api/users", use: getAll)
        router.post("api/users/find", use: get)
        router.post("api/users/create", use: create)
        router.put("api/users", Doctor.parameter, use: update)
        router.delete("api/users", use: delete)
    }

    // Decodable for post-request with user id
    struct IDDecodable : Decodable {
        let id: Int
    }

    // CRUD-Operations
    func getAll(_ request: Request) throws -> Future<[Doctor]> {
        return try request.transaction(on: .mysql) { connection in
            return Doctor.query(on: connection).all()
        }
    }

    func get(_ request: Request) throws -> Future<Doctor> {
         return try request.transaction(on: .mysql) { connection in
            return try request
                    .content
                    .decode(IDDecodable.self)
                    .flatMap(to: Doctor.self) { idDecodable in
                        return try Doctor.find(idDecodable.id, on: connection).map { user in
                            guard let user = user else {
                                throw Abort(.noContent, reason: "No user with id \(idDecodable.id)")
                            }
                            return user
                        }
            }
        }
    }

    func create(_ request: Request) throws -> Future<Doctor> {
        return try request.transaction(on: .mysql) { connection in
            return try request
                    .content
                    .decode(Doctor.self)
                    .flatMap(to: Doctor.self) { user in
                        return user.save(on: request)
                    }
        }
    }

    func update(_ request: Request) throws -> Future<Doctor> {
        return try request.transaction(on: .mysql) { connection in
            return try flatMap(
                    to: Doctor.self,
                    request.parameters.next(Doctor.self),   // get existing User from the id delivered as GET-Parameter
                    request.content.decode(Doctor.self)) {  // get updated User from request JSON

                user, newUser in
                user.firstName = newUser.firstName
                user.lastName = newUser.lastName
                user.email = newUser.email
                user.username = newUser.username
                return user.save(on: connection)
            }
        }
    }

    func delete(_ request: Request) throws -> Future<HTTPStatus> {
        return try request.transaction(on: .mysql) { connection in
            return try request
                    .content
                    .decode(Doctor.self)                     // TODO: Only send users id
                    .flatMap(to: HTTPStatus.self) { user in
                        return try user.delete(on: connection)
                                .transform(to: .noContent)
                    }
        }
    }
}