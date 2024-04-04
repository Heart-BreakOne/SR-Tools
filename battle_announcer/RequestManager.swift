//
//  RequestManager.swift
//  battle announcer
//
//  Created by leon on 2/21/24.
//

import Foundation

let gameUrl = "https://www.streamraiders.com/api/game/"

func getHeaders() -> String {
    let accessInfo = UserDefaults.standard.object(forKey: "accessInfo")!
    //return "\"Cookie\": \"ACCESS_INFO=\"\(accessInfo);\"User-Agent\": Mozilla/5.0"
    return "ACCESS_INFO=\(accessInfo)"
}

func checkBattle() throws {
    
    getGameVersion { dataVersion, version in
        let dV = dataVersion!
        let v = version!
        let raidUrl = "\(gameUrl)?cn=getActiveRaidsLite?clientPlatform=MobileLite&isCaptain=0&clientVersion=\(v)&gameDataVersion=\(dV)&command=getActiveRaidsLite"
        
        makeRequest(url: raidUrl) { decodedResponse in
            let data = decodedResponse.data!
            let twitchUserName = data[0].twitchUserName
            let type = data[0].type
            let newCreationDate = data[0].creationDate
            let opName = data[0].opponentTwitchUserName
            
            let powerLimit = Int(data[0].powerLimit ?? "100") ?? 100
            let powerCurrent = Int(data[0].powerCurrent ?? "50") ?? 50
            
            let opponentLimit = Int(data[0].opponentPowerLimit ?? "100") ?? 100
            let opponentCurrent = Int(data[0].opponentPowerCurrent ?? "50") ?? 50

            let oldCreationDate = UserDefaults.standard.object(forKey: "oldCreationDate")
            if (oldCreationDate as? String == newCreationDate) {
                let hasPlayedTTS = UserDefaults.standard.object(forKey: "hasPlayedTTS") as? Bool ?? false
                if(!hasPlayedTTS && powerCurrent >= powerLimit && opponentCurrent >= opponentLimit) {
                    playTTS(ttsString: "Attention, the battle is ready to start.")
                    UserDefaults.standard.set(true, forKey: "hasPlayedTTS")
                    UserDefaults.standard.synchronize()
                }
                return
            } else {
                UserDefaults.standard.set(newCreationDate, forKey: "oldCreationDate")
                UserDefaults.standard.synchronize()
            
                //Clash type = 2. Duel type = 5
                if (type != "2" && type != "5") {
                    print("Returning. Game mode is \(type ?? "nil")")
                    return
                }
                
                if let username = UserDefaults.standard.object(forKey: "tUsername") as? String {
                    if let twitchUsername = twitchUserName {
                        if (username != twitchUsername.lowercased()) {
                            print("Returning. Captain is \(twitchUserName ?? "nil")")
                            return
                        }
                    }
                }

                
                let ttsString = "We have found a match against \(opName ?? "nil"). Prepare to place your units."
                playTTS(ttsString: ttsString)
                UserDefaults.standard.set(false, forKey: "hasPlayedTTS")
                UserDefaults.standard.synchronize()
            }

        }
    }
}

// Get up to date version and data version from the game
func getGameVersion(completion: @escaping (String?, String?) -> Void) {
    makeRequest(url: gameUrl) { decodedResponse in
        let info = decodedResponse.info
        let version = info.version
        let dataVersion = info.dataVersion
        
        completion(dataVersion, version)
    }
}

func makeRequest(url: String, completion: @escaping ((battle_announcer.GameData) -> Void)) {
    
    let accessToken = getHeaders()
    
    let url = URL(string: url)!
    
    var request = URLRequest(url: url)
    
    request.httpMethod = "GET"
    
    request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
    request.setValue(accessToken, forHTTPHeaderField: "Cookie")
    
    let session = URLSession.shared
    
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


