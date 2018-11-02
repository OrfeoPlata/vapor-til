import Vapor
import FluentPostgreSQL

final class Acronym: Codable {
    var id: Int?
    var short: String
    var long: String
    
    init(short: String, long: String){
        self.short = short
        self.long = long
    }
}

//Make Acronym conform to Fluent is Model
extension Acronym: PostgreSQLModel {}

//Make the model conform to Migration
extension Acronym: Migration {}

//Make Acronym conform to Content
extension Acronym: Content {}

