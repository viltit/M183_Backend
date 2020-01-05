import Foundation
import Vapor

// this middleware should be activated after SessionMiddleware
final class AdminAuthentication : Middleware {
    func respond(to request: Request, chainingTo next: Responder) throws -> Future<Response> {
        return try request.getUserFromSession().flatMap { user in

            let logger = try request.make(Logger.self)
            logger.info("User \(user.firstName), \(user.lastName) is trying to access an admin-protected page")
            if (user.role != .admin) {
                logger.warning("User \(user.firstName), \(user.lastName) has insufficient rights!")
                throw Abort(.forbidden)
            }

            return try next.respond(to: request)
        }
    }
}