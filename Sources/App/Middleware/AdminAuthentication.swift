import Foundation
import Vapor

// this middleware should be activated after SessionMiddleware
final class AdminAuthentication : Middleware {
    func respond(to request: Request, chainingTo next: Responder) throws -> Future<Response> {
        return try request.getUserFromSession().flatMap { user in
            if (user.role != .admin) {
                throw Abort(.forbidden)
            }
            return try next.respond(to: request)
        }
    }
}