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
        try validations.add(\.password, .count(6...))

        // TODO: Add custom validation rules for password
        // let regex =  Matches("^(?=.*[A-Z])(?=.*[a-z])(?=.*[!@#$&*])(?=.*[0-9]).{8}$")

        return validations
    }
}