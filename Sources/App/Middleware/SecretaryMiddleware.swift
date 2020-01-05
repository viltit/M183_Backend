import Foundation
import Vapor

final class SecretaryMiddleware : Middleware {

    func respond(to request: Request, chainingTo next: Responder) throws -> Future<Response> {
        return try request.getUserFromSession().flatMap { user in

            let logger = try request.make(Logger.self)
            logger.info("A user named \(user.firstName), \(user.lastName) is trying to access a secretary-page.")

            if (user.role != .admin && user.role != .nurse) {
                logger.warning("User \(user.firstName), \(user.lastName) has insufficient rights!")
                throw Abort(.forbidden)
            }
            return try next.respond(to: request)
        }
    }
}
