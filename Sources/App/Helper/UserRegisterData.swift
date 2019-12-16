/**
    Helper Struct to map a JSON with User registration Data to a Swift Structure
    The main goal of this struct is to validate user input. That is why we split it from the User-Class
    (we could have implemented all the functionality there)
*/

import Foundation
import Vapor

struct UserRegisterData : Content {

    let firstName:  String
    let lastName:   String
    let email:      String
    let role:       User.Role
    let password:   String
    // TODO: Confirmation Password
}

// conform to Validatable to use Vapors in-built validation tools. Reflectable is needed for this.
extension UserRegisterData : Validatable, Reflectable {

    // method needed to conform to Validatable
    public static func validations() throws -> Validations<UserRegisterData> {
        var validations = Validations(UserRegisterData.self)
        try validations.add(\.firstName, .alphanumeric && .count(3...))
        try validations.add(\.lastName, .alphanumeric && .count(3...))
        try validations.add(\.email, .email)
        try validations.add(\.password, .count(8...))

        // Add a custom validation rule: Password must contain a number or symbol
        try validations.add("password_rule") { model in
            if !(model.password.rangeOfCharacter(from: .decimalDigits) || model.password.rangeOfCharacter(from: .symbols)) {
                throw BasicValidationError("Password must include at least one digit or one special character.")
            }
        }

        return validations
    }
}