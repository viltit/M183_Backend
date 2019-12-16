import Foundation
import Vapor
import Authentication

struct LoginPostData : Content {
    let email: String
    let password: String
}

struct LoginController : RouteCollection {

    func boot(router: Router) throws {
        router.post("login", use: login)
        router.get("logout", use: logout)
        router.get("loginStatus", use: loginStatus)
    }

    func login(_ request: Request) throws -> Future<User.Public> {
        // print(request.http.headers.description)
        return try request.transaction(on: .mysql) { connection in
            return try request.content.decode(LoginPostData.self).flatMap(to: User.Public.self) { data in
                return try User.authenticate(
                        username: data.email,
                        password: data.password,
                        using: BCryptDigest(),
                        on: connection).map(to: User.Public.self) { user in

                    guard let user = user else {
                        throw Abort(.unauthorized)
                    }

                    // authenticate the session
                  //  try request.authenticateSession(user)
                    try request.session()["userID"] = "\(try user.requireID())"

                    print("LOGIN with Session id ", try request.session()["userID"])

                    return user.toPublic()
                }
            }
        }
    }

    func logout(_ request: Request) throws -> String {

        try print("LOGOUT with Session id: ", request.session()["userID"])

        // THIS DOES ALL NOT WORK - Session is restored "by magic" on the next request
        // try request.session()["userID"] = nil
        try request.unauthenticateSession(User.self)
        try request.destroySession()

        return "logout"
    }

    func loginStatus(_ request: Request) throws -> Future<User.Public> {
        if try !request.hasSession() {
            throw Abort(.unauthorized)
        }
        let session = try request.session()
        guard let _ = session["userID"] else {
            throw Abort(.unauthorized)
        }
        return try request.getUserFromSession().map { user in
            return user.toPublic()
        }
    }
}
