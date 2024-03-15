//
//  GameRequestManager.swift
//  PVP Live Captains
//
//  Created by leon on 3/14/24.
//

import Foundation

let gameUrl = "https://www.streamraiders.com/api/game/"

func getUserData() -> (String, String, String, String) {
    
    var token = UserDefaults.standard.object(forKey: "token") as! String
    let userId = String(token.split(separator: "%").first ?? "")
    token = "ACCESS_INFO=\(token)"
    let clientVersion = UserDefaults.standard.object(forKey: "clientVersion") as? String ?? ""
    let dataVersion = UserDefaults.standard.object(forKey: "dataVersion") as? String ?? ""
    
    return (token, userId, clientVersion, dataVersion)
    
}

func updateGameData() {
    let url = "\(gameUrl)?cn=trackEvent&command=trackEvent&eventName=load_timing_init&eventData={\"Type\":\"Init\"}"
    
    makeRequest(urlString: url) { data in
        guard let data = data else {
            print("No data to decode")
            return
        }
        do {
            if let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                
                let status = dict["status"] as! String
                if status != "success" {
                    return
                }
                let info = dict["info"] as! [String: Any]
                let d = info["dataVersion"] as! String
                let cV = info["version"] as! String
                
                UserDefaults.standard.setValue(d, forKey: "dataVersion")
                UserDefaults.standard.setValue(cV, forKey: "clientVersion")
                UserDefaults.standard.synchronize()
            }
        } catch {
            print("Error decoding data: \(error)")
        }
    }
    
}

let raidStates: [(Int, String)] = [
    (1, "WAITING TO FIND BATTLE"),
    (4, "PLACEMENT PERIOD"),
    (5, "BATTLE WILL BE READY SOON"),
    (7, "NEEDS TO START BATTLE"),
    (10, "NEEDS TO COLLECT REWARD"),
    (11, "IS IN PLANNING PERIOD"),
]

func getLiveCaptainsData(completion: @escaping (String) -> Void) {
    let (_, userId, clientVersion, dataVersion) = getUserData()
    var string = ""
    let searchUrl = "\(gameUrl)?cn=getCaptainsForSearch&userId=\(userId)&isCaptain=0&gameDataVersion=\(dataVersion)&command=getCaptainsForSearch&page=1&resultsPerPage=30&filters={ \"mode\":\"clash\", \"isPlaying\": \"1\"}&clientVersion=\(clientVersion)&clientPlatform=WebGL"
    
    
    makeRequest(urlString: searchUrl) { data in
        guard let data = data else {
            print("No data to decode")
            return
        }
        do {
            if let gameData = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                
                let status = gameData["status"] as! String
                if status != "success" {
                    print(gameData["errorMessage"]!)
                    return
                }
                
                if let dataDict = gameData["data"] as? [String: Any] {
                    if let captains = dataDict["captains"] as? [Any] {
                        for index in (0..<captains.count).reversed() {
                            let captain = captains[index]
                            if captain is NSNull {
                                continue
                            }
                            if let cap = CaptainData(json: captain as! [String : Any]) {
                                let isLive = cap.isLive
                                let live = isLive == "1" ? "LIVE" : "OFFLINE"
                                
                                let raidStateId = cap.raidState
                                var stateString = ""
                                if let state = raidStates.first(where: { $0.0 == raidStateId }) {
                                    stateString = state.1
                                } else {
                                    stateString = "Status is unknown"
                                }
                                
                                let capName = cap.twitchDisplayName
                                string += "\(live) \(capName). \(stateString)\n"
                            }
                        }
                    }
                }
            }
        } catch {
            print("Error decoding data: \(error)")
        }
        completion(string)
    }
}


func makeRequest(urlString: String, completion: @escaping ((Data?) -> Void)) {
    let (token, _, _, _) = getUserData()
    let url = URL(string: urlString)!
    
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue(token, forHTTPHeaderField: "Cookie")
    request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
    
    let session = URLSession(configuration: .default)
    
    let task = session.dataTask(with: request) { data, response, error in
        completion(data)
    }
    
    task.resume()
    
}
