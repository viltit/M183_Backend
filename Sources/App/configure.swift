import FluentMySQL
import Leaf
import Vapor
import Authentication

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {

    // use a different database for test cases
    let database = (env == .testing) ? "m223_tests" : "m223"

    // Register providers first
    try services.register(FluentMySQLProvider())
    try services.register(LeafProvider())

    // Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    // Register middleware
    var middlewares = MiddlewareConfig()    // Create _empty_ middleware config

    // register Authentication Middleware
    try services.register(AuthenticationProvider())

    // Register Fluent command line arguments -> we can delete the testing database before each test
    var commandConfig = CommandConfig.default()
    commandConfig.useFluentCommands()
    services.register(commandConfig)

    // Allow cross origin resource sharing for local testing
    let corsConfiguration = CORSMiddleware.Configuration(
            allowedOrigin: .all,
            allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
            allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin]
    )
    let corsMiddleware = CORSMiddleware(configuration: corsConfiguration)
    middlewares.use(corsMiddleware)
    middlewares.use(ErrorMiddleware.self)   // Catches errors and converts to HTTP response

    // Add session middleware. Enables session for all requests
    middlewares.use(SessionsMiddleware.self)

    // Configure the KeyCache (used for Session handling) to be in memory:
    config.prefer(MemoryKeyedCache.self, for: KeyedCache.self)

    services.register(middlewares)

    // Configure a MySQL database
    // MySQL Database Docker container name: "m223"
    // TODO: Do not connect as root!
    // TODO: Set password as environment variable!
    let mySQLConfig = MySQLDatabaseConfig(
            hostname: "172.17.0.2", 
            port: 3306,
            username: "root",
            password: "viltit",
            database: database)
    let mysql = try MySQLDatabase(config: mySQLConfig)


    // Register the configured database to the database config.
    var databases = DatabasesConfig()
    databases.add(database: mysql, as: .mysql)
    services.register(databases)

    // configure migration. Note: Vapor will NOT alter the database when you change the Model.
    var migrations = MigrationConfig()
    migrations.add(model: User.self, database: .mysql)
    migrations.add(model: Patient.self, database: .mysql)
    migrations.add(model: PatientEntry.self, database: .mysql)
    migrations.add(model: Token.self, database: .mysql)
    migrations.add(migration: AdminUser.self, database: .mysql)   // note this is not a model
    services.register(migrations)
}
