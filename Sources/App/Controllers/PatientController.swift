
import Foundation
import FluentMySQL
import Vapor


struct PatientController : RouteCollection {
    func boot(router: Router) throws {
        router.post("api/patient", use: create)
        router.put("api/patient", Patient.parameter, use: update)
        router.delete("api/patient", use: delete)
        router.post("api/patient/doctor/", use: getDoctor)
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

    func getDoctor(_ request: Request) throws -> Future<Doctor> {
        return try request.transaction(on: .mysql) { connection in
            return try request
                    .content
                    .decode(IDDecodable.self).flatMap(to: Doctor.self) { id in
                        return Patient.find(id.id, on: connection).flatMap { patient in
                            guard let patient = patient else {
                                throw Abort(.noContent)
                            }
                            return try patient.doctor.get(on: connection)
                        }
                    }
        }
    }

}
