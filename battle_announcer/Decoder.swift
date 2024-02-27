import Foundation

// MARK: - GameData
struct GameData: Codable {
    let info: Info
    let status: String
    let errorMessage: String?
    let data: [Datum]?
}

// MARK: - Info
struct Info: Codable {
    let version: String
    let dataPath: String
    let dataVersion, serverTime, clientVersion: String
}

// MARK: - Encode/decode helpers
extension GameData {
    init(data: Data) throws {
        self = try JSONDecoder().decode(GameData.self, from: data)
    }
    
    func encode() throws -> Data {
        return try JSONEncoder().encode(self)
    }
}

// MARK: - Datum
struct Datum: Codable {
    let twitchUserName: String?
    let type: String?
    let creationDate: String?
    let opponentTwitchUserName: String?
    let powerLimit: String?
    let powerCurrent: String?
    let opponentPowerLimit: String?
    let opponentPowerCurrent: String?
}
