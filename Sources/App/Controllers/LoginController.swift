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
    }

    func login(_ request: Request) throws -> Future<String> {
        return try request.transaction(on: .mysql) { connection in
            return try request.content.decode(LoginPostData.self).flatMap(to: String.self) { data in
                return try User.authenticate(
                        username: data.email,
                        password: data.password,
                        using: BCryptDigest(),
                        on: connection).map(to: String.self) { user in

                    guard let user = user else {
                        throw Abort(.unauthorized)
                    }

                    // authenticate the session
                    try request.authenticateSession(user)
                    try request.session()["id"] = "\(user.sessionID!)"

                    print("SESSION: ", try request.session()["id"])

                    return "Done"
                }
            }
        }
    }
}


/*
func loginAction(_ request: Request, userData: LoginPostData) throws -> Future<Response> {
    return User.authenticate()
}
*/