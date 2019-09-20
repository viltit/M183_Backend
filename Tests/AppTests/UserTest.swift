@testable import App   // @testable allows to access fileprivate methods
import Vapor
import FluentMySQL
import XCTest


final class UserTests: XCTestCase {

    // needed to run tests on ubuntu:
    static let allTests = [
        ("testUserSaveAndLoad", testUserSaveAndLoad)
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

    func testUserSaveAndLoad() throws {

        let firstName = "test"
        let lastName = "user"
        let email = "test.user@testuser.ch"

        let user = User(firstName: firstName, lastName: lastName, email: email, role: .doctor)
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
    }
}
