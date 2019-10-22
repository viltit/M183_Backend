import Foundation
import Vapor
import Fluent
import Crypto   // to hash and salt user passwords with BCrypt
import Authentication

// helper struct for image uploads
struct ImageUploadData : Content {
    var picture: Data
}

// Defines all routes to the User
struct UserController: RouteCollection {

    // register routes
    func boot(router: Router) throws {

        let routes = router.grouped("api", "users")

        // register password-protected route for login:
        let authMiddleware = User.basicAuthMiddleware(using: BCryptDigest())
        let authRoute = routes.grouped(authMiddleware)
        authRoute.post("login", use: login)

        // register session-protected route for all other user actions:
        let sessionRoute = routes.grouped(User.authSessionsMiddleware())

        let protectedRoutes = sessionRoute.grouped(SessionAuthenticationMiddleware())

        protectedRoutes.get(use: getAll)
        protectedRoutes.get("patients", User.parameter, use: getPatients)
        protectedRoutes.post("find", use: get)
        // protectedRoutes.post("create", use: create)
        protectedRoutes.put(User.parameter, use: update)
        protectedRoutes.delete(use: delete)

        // avatar
        protectedRoutes.post(User.parameter, "image", use: addImage)
        protectedRoutes.get(User.parameter, "image", use: getImage)

        let adminRoute = protectedRoutes.grouped(AdminAuthentication())
        adminRoute.post("create", use: create)
    }

    // Decodable for post-request with user id
    struct IDDecodable : Decodable {
        let id: Int
    }

    // Login: Creates an Authentication Token
    func login(_ request: Request) throws -> Future<Token> {

        // we get this method because User conforms to BasicAuthenticatable.
        // We do not even need to check email and password ourselfs !!
        // The Authentication Middleware will throw an error if the user lacks credentials
        let user = try request.requireAuthenticated(User.self)
        let token = try Token.generate(for: user)

        // the token gets saved in the database:
        return token.save(on: request)

    }

    // CRUD-Operations
    func getAll(_ request: Request) throws -> Future<[User.Public]> {
        return try request.transaction(on: .mysql) { connection in
            // User.Public is "Codable", so we can just decode a User to a User.Public:
            // print("getAll Session id: ", try request.session()["userID"])
            return User.query(on: connection).decode(data: User.Public.self).all()
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

    func get(_ request: Request) throws -> Future<User.Public> {
         return try request.transaction(on: .mysql) { connection in
            return try request
                    .content
                    .decode(IDDecodable.self)
                    .flatMap(to: User.Public.self) { idDecodable in
                        return try User.find(idDecodable.id, on: connection).map { user in
                            guard let user = user else {
                                throw Abort(.noContent, reason: "No user with id \(idDecodable.id)")
                            }
                            return user.toPublic()
                        }
            }
        }
    }

    func create(_ request: Request) throws -> Future<User.Public> {
        return try request.transaction(on: .mysql) { connection in
            return try request
                    .content
                    .decode(User.self)
                    .flatMap(to: User.Public.self) { user in
                        // hash the password before storing it:
                        user.password = try BCrypt.hash(user.password)
                        return user.save(on: connection).toPublic()
                    }
        }
    }

    func update(_ request: Request) throws -> Future<User.Public> {
        return try request.transaction(on: .mysql) { connection in
            return try flatMap(
                    to: User.Public.self,
                    request.parameters.next(User.self),   // get existing User from the id delivered .../url/id
                    request.content.decode(User.Public.self)) {  // get updated User from request JSON

                user, newUser in
                user.firstName = newUser.firstName
                user.lastName = newUser.lastName
                user.email = newUser.email
                user.role = newUser.role
                return user.save(on: connection).toPublic()
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

    func addImage(_ request: Request) throws -> Future<HTTPStatus> {
        return try flatMap(
                to: HTTPStatus.self,
                request.parameters.next(User.self),
                request.content.decode(ImageUploadData.self)) {

            user, imageData in
            let workPath = try request.make(DirectoryConfig.self).workDir
            let name = try "\(user.requireID())-\(UUID().uuidString).jpg"
            let path = workPath + "images/" + name
            FileManager().createFile(
                    atPath: path,
                    contents: imageData.picture,
                    attributes: nil)
            user.avatar = name
            return user.save(on: request).transform(to: .ok)
        }
    }

    func getImage(_ request: Request) throws -> Future<Response> {
        return try request.parameters.next(User.self)
            .flatMap(to: Response.self) { user in
                guard let filename = user.avatar else {
                    throw Abort(.notFound)
                }
                let path = try request.make(DirectoryConfig.self).workDir + filename
                return try request.streamFile(at: path)
            }
    }
}