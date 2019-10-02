
import Foundation
import FluentMySQL
import Vapor
import Authentication

struct PatientController : RouteCollection {
    func boot(router: Router) throws {

        let routes = router.grouped("api", "patient")

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
        let basicAuthMiddleware = User.basicAuthMiddleware(using: BCryptDigest())

        // instantiate a GuardAuthenticationMiddleware -> ensures that request contain valid authentication
        let guardAuthMiddleware = User.guardAuthMiddleware()

        // chain these two middlewares together and create protected routes:
        let protected = routes.grouped(
                basicAuthMiddleware,
                guardAuthMiddleware
        )

        protected.post("api/patient", use: create)
        protected.put("api/patient", Patient.parameter, use: update)
        protected.delete("api/patient", use: delete)
        protected.post("api/patient/doctor/", use: getDoctor)

    }

    // Decodable for post-request with user id
    struct IDDecodable : Decodable {
        let id: Int
    }

    func create(_ request: Request) throws -> Future<Patient> {
        return try request.transaction(on: .mysql) { connection in
            return try request
                    .content
                    .decode(Patient.self)
                    .flatMap(to: Patient.self) { patient in
                        return try patient.save(on: connection)
                    }
        }
    }

    func update(_ request: Request) throws -> Future<Patient> {
        return try request.transaction(on: .mysql) { connection in
            return try flatMap(
                    to: Patient.self,
                    request.parameters.next(Patient.self),        // get the patient from database by id
                    request.content.decode(Patient.self)) {       // get the new patient from requests json
                        patient, newPatient in
                        patient.firstName = newPatient.firstName
                        patient.lastName = newPatient.lastName
                        patient.email = newPatient.email
                        patient.docID = newPatient.docID
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
