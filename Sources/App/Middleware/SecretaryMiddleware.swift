import Foundation
import Vapor

final class SecretaryMiddleware : Middleware {

    func respond(to request: Request, chainingTo next: Responder) throws -> Future<Response> {
        return try request.getUserFromSession().flatMap { user in
            if (user.role != .admin && user.role != .nurse) {
                throw Abort(.forbidden)
            }
            return try next.respond(to: request)
        }
    }
}
