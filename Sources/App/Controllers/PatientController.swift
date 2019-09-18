
import Foundation
import FluentMySQL
import Vapor


struct PatientController : RouteCollection {
    func boot(router: Router) throws {
        router.post("api/patient", use: create)
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
