import Foundation

// MARK: - Active Quests
struct QuestData: Codable {
    let info: Info
    let status: String
    let errorMessage: String?
    let data: [Datum]?
}
struct Datum: Codable {
    let currentQuestId: String?
    let questSlotId: String?
    let completedQuestIds: String?
    let currentProgress: String?
}

// MARK: - Quests json list
struct SheetsData: Codable {
    let sheets: Sheets
}

struct Sheets: Codable {
    let Quests: [String: Quest]
}

// MARK: - Quests - Local json file
struct Quest: Codable {
    let GoalAmount: Int
    let QuestIds: String
    let Uid: String
}

// MARK: - Game data Info
struct Info: Codable {
    let version: String
    let dataPath: String
    let dataVersion, serverTime, clientVersion: String
}

// MARK: - Encode/decode helpers
extension QuestData {
    init(data: Data) throws {
        self = try JSONDecoder().decode(QuestData.self, from: data)
    }
    
    func encode() throws -> Data {
        return try JSONEncoder().encode(self)
    }
}
