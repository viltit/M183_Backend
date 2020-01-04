import FluentMySQL
import Leaf
import Vapor
import Authentication
import VaporSecurityHeaders // CSP

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {

    // use a different database for test cases
    let database = (env == .testing) ? "m183_tests" : "m183"

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
    // IT TOOK ME HOURS TO FIGURE THIS OUT: allowedOrigin = .all WILL DISABLE COOKIES FOR REQUESTS FROM LOCALHOST
    let corsConfiguration = CORSMiddleware.Configuration(
            allowedOrigin: .custom("https://localhost:3000/"),
            allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
            allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin, .cookie, .setCookie],
            allowCredentials: true
    )
    let corsMiddleware = CORSMiddleware(configuration: corsConfiguration)
    middlewares.use(corsMiddleware)
    middlewares.use(ErrorMiddleware.self)   // Catches errors and converts to HTTP response

    // Add session middleware. Enables session for all requests
    // set http only for the session cookie and and expiry date
    let sessionsConfig = SessionsConfig(cookieName: "vapor-session") { value in
        return HTTPCookieValue(string: value,
                expires: Date(timeIntervalSinceNow: 60 * 60),    // 1 hour
                maxAge: nil,
                domain: nil,
                path: "/",
                isSecure: true,     // TODO: browser refuses to connect on true (can not verify certificate)
                isHTTPOnly: true,
                sameSite: nil)
    }
    services.register(sessionsConfig)
    middlewares.use(SessionsMiddleware.self)

    // Configure the KeyCache (used for Session handling) to be in memory:
    config.prefer(MemoryKeyedCache.self, for: KeyedCache.self)

    // Add Content Security Headers:
    // The default factory will add the following headers:
    // x-content-type-options: nosniff
    // content-security-policy: default-src 'self'
    // x-frame-options: DENY
    // x-xss-protection: 1; mode=block
    // we also add the strict transport security (HSTS)
    let strictTransportSecurityConfig = StrictTransportSecurityConfiguration(
            maxAge: 31536000,
            includeSubdomains: true,
            preload: true)
    let securityHeaderFactory = SecurityHeadersFactory().with(strictTransportSecurity: strictTransportSecurityConfig)
    services.register(securityHeaderFactory.build())
    middlewares.use(SecurityHeaders.self)


    services.register(middlewares)

    // Configure a MySQL database
    // MySQL Database Docker container name: "m223"

    // TODO: Set password as environment variable!
    let mySQLConfig = MySQLDatabaseConfig(
            hostname: "172.17.0.2", 
            port: 3306,
            username: "VaporUser",     // TODO: Migration will not work anymore  since user can not create tables !!
            password: "VaporAPI",
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
