
/*
    I am not sure if this class is needed. However, I did NOT find any such Middleware in Vapor
    -> This Middleware authenticates a session and throws a HTTP-Error if it fails
*/

import Vapor

final class SessionAuthenticationMiddleware : Middleware {

    // this function is defined by protocol Middleware and will be executed automaticly on all Requests
    // that are bound to a route using this middleware
    func respond(to request: Request, chainingTo next: Responder) throws -> Future<Response> {

        try print("Session Auth Middleware acitvated for session id \(try request.session()["userID"])")

        let session = try request.session()
        guard let id = session["userID"] else {
            throw Abort(.forbidden)
        }
        return try next.respond(to: request)
    }
}