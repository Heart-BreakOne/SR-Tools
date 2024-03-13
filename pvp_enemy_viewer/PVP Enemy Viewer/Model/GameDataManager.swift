//
//  EnemyMap.swift
//  PVP Enemy Viewer
//
//  Created by leon on 3/12/24.
//

import Foundation

let gameUrl = "https://www.streamraiders.com/api/game/"

func getUserData() -> (String, String, String, String) {
    
    var token = UserDefaults.standard.object(forKey: "token") as! String
    let userId = String(token.split(separator: "%").first ?? "")
    token = "ACCESS_INFO=\(token)"
    let clientVersion = UserDefaults.standard.object(forKey: "clientVersion") as! String
    let dataVersion = UserDefaults.standard.object(forKey: "dataVersion") as! String
    
    return (token, userId, clientVersion, dataVersion)
    
}

func fetchEnemyData(enemyName: String, completion: @escaping ((Double, Double, NSArray, NSArray, NSArray, NSArray, [Marker], [Captain])) -> Void) {
    let dispatchGroup = DispatchGroup()
    var battlePlans: [String: Any] = [:]
    var mapScale = -1
    var gridWidth = 0.0
    var gridLength = 0.0
    var allyZones: NSArray = []
    var neutralZones: NSArray = []
    var purpleZones: NSArray = []
    var enemyZones: NSArray = []
    var raidPlacements: Any?

    dispatchGroup.enter()
    getRaidData { data in
        defer {
            dispatchGroup.leave()
        }
        guard let data = data else {
            print("No data to decode")
            return
        }
        do {
            if let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                let status = dict["status"] as! String
                if status != "success" {
                    print(dict["errorMessage"] as! String)
                    return
                }
                let data = dict["data"] as! [[String: Any]]
                let (_, userId, clientVersion, dataVersion) = getUserData()
                for slot in data {
                    let slotIndex = slot["userSortIndex"] as! String
                    if slotIndex == "1" {
                        let raidId = slot["raidId"] as! String
                        
                        let getRaidUrl = "\(gameUrl)?cn=getRaid&userId=\(userId)&isCaptain=0&gameDataVersion=\(dataVersion)&command=getRaid&raidId=\(raidId)&maybeSendNotifs=False&&clientVersion=\(clientVersion)&clientPlatform=WebGL"
                        dispatchGroup.enter()
                        makeRequest(urlString: getRaidUrl) { cRaidData in
                            defer {
                                dispatchGroup.leave()
                            }
                            guard let cRaidData = cRaidData else {
                                print("No data to decode")
                                return
                            }
                            do {
                                if let r = try JSONSerialization.jsonObject(with: cRaidData, options: []) as? [String: Any] {
                                    let rData = r["data"] as! [String: Any]
                                    raidPlacements = rData["placements"]
                                }
                            } catch {
                                print("Error decoding data: \(error)")
                            }
                        }
                        
                        let planUrl = "\(gameUrl)?cn=getRaidPlan&userId=\(userId)&isCaptain=0&gameDataVersion=\(dataVersion)&command=getRaidPlan&raidId=\(raidId)&clientVersion=\(clientVersion)&clientPlatform=WebGL"
                        dispatchGroup.enter()
                        makeRequest(urlString: planUrl) { planData in
                            defer {
                                dispatchGroup.leave()
                            }
                            guard let planData = planData else {
                                print("No data to decode")
                                return
                            }
                            do {
                                if let plan = try JSONSerialization.jsonObject(with: planData, options: []) as? [String: Any] {
                                    let dtPlan = plan["data"] as? [String: Any]
                                    battlePlans = dtPlan?["planData"] as? [String: Any] ?? [:]
                                }
                            } catch {
                                print("Error decoding data: \(error)")
                            }
                        }
                        
                        let bg = slot["battleground"] as! String
                        let battleUrl = "https://d2k2g0zg1te1mr.cloudfront.net/maps/\(bg).txt"
                        dispatchGroup.enter()
                        makeRequest(urlString: battleUrl) { data in
                            defer {
                                dispatchGroup.leave()
                            }
                            guard let data = data else {
                                print("No data to decode")
                                return
                            }
                            do {
                                if let battle = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                                    mapScale = battle["MapScale"] as! Int
                                    gridWidth = battle["GridWidth"] as! Double
                                    gridLength = battle["GridLength"] as! Double
                                    allyZones = battle["PlayerPlacementRects"] as? NSArray ?? []
                                    neutralZones = battle["NeutralPlacementRects"] as? NSArray ?? []
                                    purpleZones = battle["HoldingZoneRects"] as? NSArray ?? []
                                    enemyZones = battle["EnemyPlacementRects"] as? NSArray ?? []
                                }
                            } catch {
                                print("Error decoding data: \(error)")
                            }
                        }
                    }
                }
            }
        } catch {
            print("Error decoding data: \(error)")
        }
    }
    
    dispatchGroup.notify(queue: .main) {
        if mapScale >= 0 {
            gridWidth = round(Double(41 * mapScale))
            gridLength = round(Double(29 * mapScale))
        }
        let markers = normalizeBattlePlan(battlePlans: battlePlans, gridWidth: gridWidth, gridLength: gridLength)
        let eCapPosition = getEnemyCaptain(raidPlacements: raidPlacements, enemyName: enemyName)
        
        // Call the completion handler with the result
        completion((gridWidth, gridLength, allyZones, neutralZones, purpleZones, enemyZones, markers, eCapPosition))
    }
}


func joinCaptain(enemyName: String, gameMode: String) {
    //Join matching captain on slot 1
    leaveCaptain()
    
    let (_, userId, clientVersion, dataVersion) = getUserData()
    // Search captain, get captain ID, join captain
    let searchUrl = "\(gameUrl)?cn=getCaptainsForSearch&userId=\(userId)&isCaptain=0&gameDataVersion=\(dataVersion)&command=getCaptainsForSearch&page=1&resultsPerPage=30&filters={\"twitchUserName\":\"\(enemyName)\", \"mode\":\"\(gameMode)\", \"isPlaying\": \"1\"}&clientVersion=\(clientVersion)&clientPlatform=WebGL"
    
    makeRequest(urlString: searchUrl) { data in
        guard let data = data else {
            print("No data to decode")
            return
        }
        do {
            if let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                
                let status = dict["status"] as! String
                if status != "success" {
                    print(dict["errorMessage"] as! String)
                    return
                }
                let data = dict["data"] as! [String: Any]
                let captainsData = data["captains"] as! [[String: Any]]
                for cap in captainsData {
                    let tUserName = cap["twitchUserName"] as! String
                    
                    if enemyName.lowercased() == tUserName.lowercased() {
                        let capId = cap["userId"] as! String
                        let joinUrl = "\(gameUrl)?userId=\(userId)&isCaptain=0&gameDataVersion=\(dataVersion)&command=addPlayerToRaid&userSortIndex=1&captainId=\(capId)&clientVersion=\(clientVersion)&clientPlatform=WebGL"
                        makeRequest(urlString: joinUrl) { _ in
                            // No need to handle the response.
                        }
                        break
                    }
                }
                
                
            }
        } catch {
            print("Error decoding data: \(error)")
        }
    }
}

func leaveCaptain() {
    //Leave any captain that is on slot 1
    let (_, userId, clientVersion, dataVersion) = getUserData()
    
    getRaidData { data in
        guard let data = data else {
            print("No data to decode")
            return
        }
        do {
            if let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                
                let status = dict["status"] as! String
                if status != "success" {
                    print(dict["errorMessage"] as! String)
                    return
                }
                let data = dict["data"] as! [[String: Any]]
                for slot in data {
                    let slotIndex = slot["userSortIndex"] as! String
                    if slotIndex == "1" {
                        let captainId = slot["captainId"] as! String
                        let leaveUrl = "\(gameUrl)?userId=\(userId)&isCaptain=0&gameDataVersion=\(dataVersion)&command=leaveCaptain&captainId=\(captainId)&clientVersion=\(clientVersion)&clientPlatform=WebGL"
                        
                        makeRequest(urlString: leaveUrl) { _ in
                            // No need to handle the response.
                        }
                        break
                    }
                }
                
            }
        } catch {
            print("Error decoding data: \(error)")
        }
    }
}

//Game and client version
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

//Raid data so captain can be left, joined and game data can be fetched.
func getRaidData(completion: @escaping (Data?) -> Void) {
    let (_, userId, clientVersion, dataVersion) = getUserData()
    
    let raidURL = "\(gameUrl)?cn=getActiveRaidsByUser&userId=\(userId)&isCaptain=0&gameDataVersion=\(dataVersion)&command=getActiveRaidsByUser&clientVersion=\(clientVersion)&clientPlatform=WebGL"
    
    makeRequest(urlString: raidURL) { data in
        completion(data)
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


func normalizeBattlePlan(battlePlans: [String : Any], gridWidth: Double, gridLength: Double) -> [Marker]{
    var arrayOfMarkers: [Marker] = []
    for plan in battlePlans {
        let key = plan.key
        let value = plan.value as! [Int]
        
        for i in stride(from: 0, to: value.count, by: 2) {
            
            let icon = "\(key.lowercased())"
            let x = (Double(value[i]) - gridWidth / 2.0) * 0.8
            let y = (gridLength / 2.0 - Double(value[i + 1])) * 0.8
            let width = 0.8
            let height = 0.8
            let marker = Marker(icon: icon, x: x, y: y, width: width, height: height)
            arrayOfMarkers.append(marker)
        }
        
    }
    
    return arrayOfMarkers
}

func getEnemyCaptain(raidPlacements: Any?, enemyName: String) -> [Captain] {
    let placements = raidPlacements as! [[String: Any]]
    var captain: [Captain] = []
    for p in placements {
        let xStr = p["X"] as! String
        let yStr = p["Y"] as! String
        let x = Double(xStr)!
        let y = Double(yStr)!
        let captainUnit = p["CharacterType"] as! String
        if captainUnit.contains("captain") {
            
            let cap = Captain(unit: captainUnit, x: x, y: y, width: 1.6, height: 1.6)
            captain.append(cap)
            break
        }
    }
    return captain
}
