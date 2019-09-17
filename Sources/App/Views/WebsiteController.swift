import Vapor
import Leaf

struct WebsiteController : RouteCollection {

    func boot(router: Router) throws {
        router.get(use: indexHandler)
    }

    func indexHandler(_ request: Request) throws -> Future<View> {
        return try request.view().render("index")
    }
}