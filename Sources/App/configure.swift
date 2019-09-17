import FluentMySQL
import Leaf
import Vapor

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {

    // Register providers first
    try services.register(FluentMySQLProvider())
    try services.register(LeafProvider())

    // leaf: Pefer LeafRenderer for html generation:
    config.prefer(LeafRenderer.self, for: ViewRenderer.self)

    // Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    // Register middleware
    var middlewares = MiddlewareConfig()    // Create _empty_ middleware config
    middlewares.use(ErrorMiddleware.self)   // Catches errors and converts to HTTP response
    services.register(middlewares)

    // Configure a SQLite database
    // MySQL Database Docker container name: "m223"
    // TODO: Do not connect as root!
    // TODO: Set password as environment variable!
    let mySQLConfig = MySQLDatabaseConfig(
            hostname: "172.17.0.2", 
            port: 3306,
            username: "root",
            password: "viltit",
            database: "m223")
    let mysql = try MySQLDatabase(config: mySQLConfig)


    // Register the configured database to the database config.
    var databases = DatabasesConfig()
    databases.add(database: mysql, as: .mysql)
    services.register(databases)

    // configure migration. Note: Vapor will NOT alter the database when you change the Model.
    var migrations = MigrationConfig()
    migrations.add(model: Doctor.self, database: .mysql)
    migrations.add(model: Patient.self, database: .mysql)
    migrations.add(model: PatientEntry.self, database: .mysql)
    services.register(migrations)
}
