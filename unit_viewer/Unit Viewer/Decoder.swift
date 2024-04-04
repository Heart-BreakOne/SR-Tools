//
//  Decoder.swift
//  Unit Viewer
//
//  Created by leon on 2/23/24.
//

import Foundation

// MARK: - Info
struct Info: Codable {
    let version: String
    let dataPath: String
    let dataVersion, serverTime, clientVersion: String
}

// MARK: - GameData
struct GameData: Codable {
    let info: Info
    let status: String
    let errorMessage: String?
    let data: [Datum]?
}

// MARK: - Datum
struct Datum: Codable {
    let battleground: String?
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

// MARK: - BattleGroundData
struct BattleGroundData: Codable {
    let PlacementData: [PlacementDatum]
    let MapScale: Int?
    let GridWidth: Int
    let GridLength: Int
}

struct PlacementDatum: Codable {
    var CharacterType: String
    let X: Float
    let Y: Float
}
