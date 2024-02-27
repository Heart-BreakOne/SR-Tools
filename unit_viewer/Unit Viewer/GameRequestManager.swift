//
//  GameRequestManager.swift
//  Unit Viewer
//
//  Created by leon on 2/23/24.
//

import Foundation

let gameUrl = "https://www.streamraiders.com/api/game/"
let bgUrl = "https://d1vngzyege2qd5.cloudfront.net/prod1/"

func getHeaders() -> String {
    let accessInfo = UserDefaults.standard.object(forKey: "accessInfo")!
    //return "\"Cookie\": \"ACCESS_INFO=\"\(accessInfo);\"User-Agent\": Mozilla/5.0"
    print(accessInfo)
    return "ACCESS_INFO=\(accessInfo)"
}

func getGameVersion(completion: @escaping (String?, String?) -> Void) {
    makeRequest(url: gameUrl) { decodedResponse in
        let info = decodedResponse.info
        let version = info.version
        let dataVersion = info.dataVersion
        
        completion(dataVersion, version)
    }
}

func getEnemyUnits(accessInfo: String, completion: @escaping (Int, Int, [PlacementDatum]) -> Void) {
    getGameVersion { dataVersion, version in
        let dV = dataVersion!
        let v = version!
        let raidUrl = "\(gameUrl)?cn=getActiveRaidsLite?clientPlatform=MobileLite&isCaptain=0&clientVersion=\(v)&gameDataVersion=\(dV)&command=getActiveRaidsLite"
        
        makeRequest(url: raidUrl) { decodedResponse in
            let data = decodedResponse.data!
            let bG = data[0].battleground
            var battleGroundUrl = ""
            if let bG = bG {
                battleGroundUrl = bgUrl + bG + ".txt"
            }
            getBattleGroundData(url: battleGroundUrl) { decodedResponse in
                getImageData(decodedResponse: decodedResponse) { mapWidth, mapHeight, placements in
                    completion(mapWidth, mapHeight, placements)
                }
            }
            
            
        }
        
    }
}

func getBattleGroundData(url: String, completion: @escaping ((Unit_Viewer.BattleGroundData) -> Void)) {
    
    let (request, session) = prepareRequest(url: url)
    
    let task = session.dataTask(with: request) { (data, response, error) in
        // Check for any errors
        if let error = error {
            print("Error: \(error)")
            return
        }
        
        // Check if there's data returned
        guard let data = data else {
            print("No data returned")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            // Deal with unsupported floating numbers
            decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")
            
            let decodedResponse = try decoder.decode(Unit_Viewer.BattleGroundData.self, from: data)
            completion(decodedResponse)
        } catch {
            print("Error deserializing battleground data JSON: \(error)")
        }
    }
    task.resume()
}


func makeRequest(url: String, completion: @escaping ((Unit_Viewer.GameData) -> Void)) {
    
    let (request, session) = prepareRequest(url: url)
    
    let task = session.dataTask(with: request) { (data, response, error) in
        
        // Check for any errors
        if let error = error {
            print("Error: \(error)")
            return
        }
        
        // Check if there's data returned
        guard let data = data else {
            print("No data returned")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            let decodedResponse = try decoder.decode(GameData.self, from: data)
            
            completion(decodedResponse)
            
        } catch {
            print("Error deserializing JSON: \(error)")
        }
    }
    
    task.resume()
}

func prepareRequest(url: String) -> (URLRequest, URLSession) {
    let accessToken = getHeaders()
    let url = URL(string: url)!
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
    request.setValue(accessToken, forHTTPHeaderField: "Cookie")
    let session = URLSession.shared
    return (request, session)
}


typealias ImageDataCallback = (Int, Int, [PlacementDatum]) -> Void

func getImageData(decodedResponse: Unit_Viewer.BattleGroundData, completion: @escaping ImageDataCallback) {
    let mapSize = decodedResponse.MapScale!
    var placements = decodedResponse.PlacementData
    
    var mapWidth = 0
    var mapHeight = 0
    if mapSize < 0 {
        mapWidth = decodedResponse.GridWidth
        mapHeight = decodedResponse.GridLength
    } else {
        mapWidth = Int(round(41 * Double(mapSize)))
        mapHeight = Int(round(20 * Double(mapSize)))
    }
    
    for index in placements.indices {
        var unitName = placements[index].CharacterType
        let digitsToRemove = CharacterSet(charactersIn: "0123456789")
        unitName = unitName.components(separatedBy: digitsToRemove).joined()
        placements[index].CharacterType = unitName
    }
    
    completion(mapWidth, mapHeight, placements)
}
