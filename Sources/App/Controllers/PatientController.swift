
import Foundation
import FluentMySQL
import Vapor
import Authentication

struct PatientController : RouteCollection {

    /* Instantiate a basic authentication middleware -> verifies passwords

         This "Middleware"-Stuff seems a bit magic to me.
         To quote from Ray Wenderlichs "Vapor"-Book:
         "Middleware allows you to intercept requests and responses in your application. In
         this example, basicAuthMiddleware intercepts the request and authenticates the
         user supplied. You can chain middleware together. In the above example,
         basicAuthMiddleware authenticates the user. Then guardAuthMiddleware ensures
         the request contains an authenticated user. If there’s no authenticated user,
         guardAuthMiddleware throws an error."

    */

    //TODO: Every user can update every patient -> restrict ?
    func boot(router: Router) throws {

        let routes = router.grouped("api", "patient")

        // instantiate a basic authentication middleware which verifies a User via his Token
        let tokenAuthMiddleware = User.tokenAuthMiddleware()

        // instantiate a GuardAuthenticationMiddleware -> ensures that request contain valid authentication
        let guardAuthMiddleware = User.guardAuthMiddleware()

        // chain these two middlewares together and create protected routes:
        let protected = routes.grouped(
                tokenAuthMiddleware,
                guardAuthMiddleware
        )

        // all routes go via the protection middleware now:
        protected.post(use: create)
        protected.put(Patient.parameter, use: update)
        protected.delete(use: delete)
        protected.post("doctor", use: getDoctor)

    }

    // Decodable for post-request with user id
    struct IDDecodable : Decodable {
        let id: Int
    }

    func create(_ request: Request) throws -> Future<Patient> {
        return try request.transaction(on: .mysql) { connection in
            // make sure the User is Authenticated:
            let user = try request.requireAuthenticated(User.self)
            return try request
                    .content
                    .decode(Patient.Public.self)
                    .flatMap(to: Patient.self) { patientData in
                        let patient = try Patient(
                                firstName: patientData.firstName,
                                lastName: patientData.lastName,
                                email: patientData.email,
                                docID: user.requireID()
                        )
                        return try patient.save(on: connection)
                    }
        }
    }

    /*
    - Needs a patients id in the URL to identify the patient we want to update, ie: "api/patients/1"
    - Needs the new patient data as JSON
    - TODO: Add a doctor parameter? Right now, the patient is assigned to the User that updates him
        (the secretary updates the patient -> the patient belong to the secretary)
    */
    func update(_ request: Request) throws -> Future<Patient> {
        return try request.transaction(on: .mysql) { connection in

            return try flatMap(
                    to: Patient.self,
                    request.parameters.next(Patient.self),               // get the patient from database by id
                    request.content.decode(Patient.Public.self)) {       // get the new patient from requests json

                        patient, newPatient in

                        // make sure we have an authenticated user:
                        let user = try request.requireAuthenticated(User.self)
                        patient.firstName = newPatient.firstName
                        patient.lastName = newPatient.lastName
                        patient.email = newPatient.email
                        patient.docID = try user.requireID()
                        return patient.save(on: connection)
                    }
        }
    }

    func delete(_ request: Request) throws -> Future<HTTPStatus> {
        return try request.transaction(on: .mysql) { connection in
            return try request
                    .content
                    .decode(Patient.self)
                    .flatMap(to: HTTPStatus.self) { patient in
                        return try patient.delete(on: connection)
                            .transform(to: .noContent)
                    }
        }
    }

    func getDoctor(_ request: Request) throws -> Future<User.Public> {
        return try request.transaction(on: .mysql) { connection in
            return try request
                    .content
                    .decode(IDDecodable.self).flatMap(to: User.Public.self) { id in
                        return Patient.find(id.id, on: connection).flatMap { patient in
                            guard let patient = patient else {
                                throw Abort(.noContent)
                            }
                            return try patient.doctor.get(on: connection).toPublic()
                        }
                    }
        }
    }

}
