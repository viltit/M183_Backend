import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "It works" example
    router.get { req in
        return "It works!"
    }
    
    // Basic "Hello, world!" example
    router.get("hello") { req in
        return "Hello, world!"
    }

    let userController = UserController()
    try router.register(collection: userController)

    let patientController = PatientController()
    try router.register(collection: patientController)

    let loginController = LoginController()
    try router.register(collection: loginController)
}
