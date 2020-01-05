import Foundation
import Vapor

// TODO: This is almost identical to UserRegisterData
struct UserEditData : Content {

    let firstName:  String
    let lastName:   String
    let email:      String
    let role:       User.Role
}

// conform to Validatable to use Vapors in-built validation tools. Reflectable is needed for this.
extension UserEditData : Validatable, Reflectable {

    // method needed to conform to Validatable
    public static func validations() throws -> Validations<UserEditData> {
        var validations = Validations(UserEditData.self)
        try validations.add(\.firstName, .alphanumeric && .count(3...))
        try validations.add(\.lastName, .alphanumeric && .count(3...))
        try validations.add(\.email, .email)

        return validations
    }
}