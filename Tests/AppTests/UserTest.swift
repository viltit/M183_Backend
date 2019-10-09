@testable import App   // @testable allows to access fileprivate methods
import Vapor
import FluentMySQL
import Crypto
import XCTest


final class UserTests: XCTestCase {

    // needed to run tests on ubuntu:
    static let allTests = [
        ("testValidLogin", testValidLogin),
        ("testInvalidLogin", testInvalidLogin)
        //("testUserSaveAndLoad", testUserSaveAndLoad)
    ]

    var app: Application!
    var connection: MySQLConnection!

    // executed before each test
    override func setUp() {
        try! Application.reset()
        app = try! Application.testable()
        connection = try! app.newConnection(to: .mysql).wait()
    }

    override func tearDown() {
        connection.close()
        try? app.syncShutdownGracefully()
    }

    func testValidLogin() throws {
        let validCredentials = BasicAuthorization(
                username: "admin@admin.ch",
                password: "I am visible"
        )
        var tokenHeader = HTTPHeaders()
        tokenHeader.basicAuthorization = validCredentials
        let response: Response = try app.sendRequest(to: "/api/users/login/", method: HTTPMethod.POST, headers: tokenHeader)

        XCTAssertEqual(response.http.status, .ok)

        let token = try response.content.decode(Token.self).wait()

        // TODO: Save token for further tests where we need it ?
    }

    func testInvalidLogin() throws {
        let invalidCredentials = BasicAuthorization(
                username: "admin",
                password: "admin"
        )

        var tokenHeader = HTTPHeaders()
        tokenHeader.basicAuthorization = invalidCredentials
        let response: Response = try app.sendRequest(to: "/api/users/login/", method: HTTPMethod.POST, headers: tokenHeader)

        XCTAssertEqual(response.http.status, .unauthorized)
    }

    /*
    func testUserSaveAndLoad() throws {

        let firstName = "test"
        let lastName = "user"
        let email = "test.user@testuser.ch"
        let password = "password"

        let user = User(firstName: firstName, lastName: lastName, email: email, password: password, role: .doctor)
        try user.save(on: connection).wait()



        // send a http-request to retrieve the user:
        let responder = try app.make(Responder.self)
        let request = HTTPRequest(
                method: .GET,
                url: URL(string: "/api/users")!)
        let wrappedRequest = Request(http: request, using: app)

        let response = try responder
                .respond(to: wrappedRequest)
                .wait()

        let data = try response.http.body.data!
        let loadedUser = try JSONDecoder().decode([User].self, from: data)

        XCTAssertEqual(loadedUser[0].firstName, firstName)
        XCTAssertEqual(loadedUser[0].lastName, lastName)
        XCTAssertEqual(loadedUser[0].email, email)
        XCTAssertEqual(loadedUser[0].role, .doctor)
    } */
}
