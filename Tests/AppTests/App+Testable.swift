import Vapor
@testable import App
import FluentMySQL

// this extension sets up an Application for the testing environment
extension Application {
    static func testable(envArgs: [String]? = nil) throws -> Application {
        var config = Config.default()
        var services = Services.default()
        var env = Environment.testing

        if let environmentArgs = envArgs {
            env.arguments = environmentArgs
        }

        try App.configure(&config, &env, &services)
        let app = try Application(config: config, environment: env, services: services)

        try App.boot(app)
        return app
    }

    // reset the database
    static func reset() throws {
        let revertEnvironment = ["vapor", "revert", "--all", "-y"]
        try Application.testable(envArgs: revertEnvironment).asyncRun().wait()
        let migrateEnvironment = ["vapor", "migrate", "-y"]
        try Application.testable(envArgs: migrateEnvironment).asyncRun().wait()
    }

    // helper function to send requests to the API:
    func sendRequest (to path: String,
                     method: HTTPMethod,
                     headers: HTTPHeaders = .init()
                     ) throws -> Response {


        let responder = try self.make(Responder.self)
        let request = HTTPRequest(
                method: method,
                url: URL(string: path)!,
                headers: headers)
        let wrappedRequest = Request(http: request, using: self)

        return try responder
                .respond(to: wrappedRequest)
                .wait()
    }

    func login() throws -> Response {

        let validCredentials = BasicAuthorization(
                username: "admin@admin.ch",
                password: "I am visible"
        )
        var header = HTTPHeaders()
        header.basicAuthorization = validCredentials
        let response: Response = try self.sendRequest(to: "/login", method: HTTPMethod.POST, headers: header)

        return response
    }

    // helper function to get a User Token. Needed because all routes are protected
    // TODO: Not needed anymore because we use sessions now
    func getToken() throws -> Future<String> {

        let validCredentials = BasicAuthorization(
                username: "admin@admin.ch",
                password: "I am visible"
        )
        var tokenHeader = HTTPHeaders()
        tokenHeader.basicAuthorization = validCredentials
        let response: Response = try self.sendRequest(to: "/api/users/login/", method: HTTPMethod.POST, headers: tokenHeader)

        return try response.content.decode(Token.self).map { token in
            return token.token
        }
    }
}