import Foundation
import Vapor
import Authentication

struct LoginPostData : Content {
    let email: String
    let password: String
}
/*
func loginAction(_ request: Request, userData: LoginPostData) throws -> Future<Response> {
    return User.authenticate()
}
*/