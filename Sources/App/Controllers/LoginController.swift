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

    func login(_ request: Request) throws -> Future<HTTPStatus> {
        return try request.transaction(on: .mysql) { connection in
            return try request.content.decode(LoginPostData.self).flatMap(to: HTTPStatus.self) { data in
                return try User.authenticate(
                        username: data.email,
                        password: data.password,
                        using: BCryptDigest(),
                        on: connection).map(to: HTTPStatus.self) { user in

                    guard let user = user else {
                        return HTTPStatus.unauthorized
                    }
                    try request.authenticateSession(user)
                    return HTTPStatus.ok
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