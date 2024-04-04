//
//  RequestManager.swift
//  stream raiders tools
//
//  Created by leon on 2/22/24.
//

import Foundation

let gameUrl = "https://www.streamraiders.com/api/game/"


// Get up to date version and data version from the game
func getGameVersion(completion: @escaping (String?, String?) -> Void) {
    makeRequest(url: gameUrl) { decodedResponse in
        let info = decodedResponse.info
        let version = info.version
        let dataVersion = info.dataVersion
        
        completion(dataVersion, version)
    }
}

func handleQuests() throws {
    
    getGameVersion { (dataVersion: String?, version: String?) in
        let dV = dataVersion!
        let v = version!
        let questUrl = "\(gameUrl)?cn=getUserQuests&clientVersion=\(v)&clientPlatform=WebGL&gameDataVersion=\(dV)&command=getUserQuests&isCaptain=1"
        makeRequest(url: questUrl) { decodedResponse in
            do {
                let activeQuests = decodedResponse.data!
                
                let currentDirectoryURL = URL(fileURLWithPath: #file)
                let sourceDirectoryURL = currentDirectoryURL.deletingLastPathComponent()
                let fileURL = sourceDirectoryURL.appendingPathComponent("quests.json")
                let decodedJson = try Data(contentsOf: fileURL)
                let questsDic = try JSONDecoder().decode([String: Quest].self, from: decodedJson)
                for activeQuest in activeQuests {
                    let questId = activeQuest.currentQuestId
                    let questSlotId = activeQuest.questSlotId
                    let completedQuestIds = activeQuest.completedQuestIds
                    let currentProgress = activeQuest.currentProgress

                    var isCompleted = false

                    if let questId = questId, let completedQuestIds = completedQuestIds {
                        if completedQuestIds.contains(questId) {
                            isCompleted = true
                        }
                    }
                    
                    if (questId == nil || isCompleted) {
                        continue
                    }
                    
                    var currentProgressInt: Int
                    if let currentProgress = currentProgress, let convInt = Int(currentProgress) {
                        currentProgressInt = convInt
                    } else {
                        continue
                    }
                    
                    for quest in questsDic {
                        let questKey = quest.key
                        if (questKey == questId) {
                            let questAmount = quest.value.GoalAmount
                            if (currentProgressInt >= questAmount) {
                                let qI = questSlotId!
                                let questUrl = "\(gameUrl)?cn=collectQuestReward&slotId=\(qI)&autoComplete=False&clientVersion=\(v)&clientPlatform=WebGL&gameDataVersion=\(dV)&command=collectQuestReward&isCaptain=1"
                                makeRequest(url: questUrl) { decodedResponse in
                                    // Do nothing with the response
                                }
                                break
                            }
                        }

                    }
                }

            } catch {
                print("Error: \(error)")
            }
        }
    }
}

func updateQuests() {
    
    makeRequest(url: gameUrl) { decodedResponse in
        let dataUrl = decodedResponse.info.dataPath
        getGameData(dataUrl: dataUrl) { decodedResponse in
            let json = decodedResponse.sheets.Quests
            let jsonData = try? JSONEncoder().encode(json)
            do {
                let currentDirectoryURL = URL(fileURLWithPath: #file)
                let sourceDirectoryURL = currentDirectoryURL.deletingLastPathComponent()
                
                let fileURL = sourceDirectoryURL.appendingPathComponent("quests.json")
                
                // Write data to file
                try jsonData!.write(to: fileURL, options: .atomic)
                
                print("Quests file updated at \(fileURL)")
            } catch {
                print("Error: \(error.localizedDescription)")
            }
            
        }
    }
}


func makeRequest(url: String, completion: @escaping ((stream_raiders_tools.QuestData) -> Void)) {
    
    let (session, request) = prepareRequest(requestUrl: url)
    
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
            let decodedResponse = try decoder.decode(QuestData.self, from: data)
            
            completion(decodedResponse)
            
        } catch {
            print("Error deserializing JSON: \(error)")
        }
    }
    
    task.resume()
}


func getGameData(dataUrl: String, completion: @escaping ((stream_raiders_tools.SheetsData) -> Void)) {
    
    let (session, request) = prepareRequest(requestUrl: dataUrl)
    
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
            let decodedResponse = try decoder.decode(SheetsData.self, from: data)
            completion(decodedResponse)
            
        } catch {
            print("Error deserializing JSON: \(error)")
        }
    }
    
    task.resume()
}

func prepareRequest(requestUrl: String) -> (URLSession, URLRequest) {

    var accessInfo = UserDefaults.standard.object(forKey: "accessInfo")! as! String
    accessInfo = "ACCESS_INFO=\(accessInfo)"
    let url = URL(string: requestUrl)!
    
    var request = URLRequest(url: url)
    
    request.httpMethod = "GET"
    
    request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
    request.setValue(accessInfo, forHTTPHeaderField: "Cookie")
    
    let session = URLSession.shared
    
    return (session, request)
}
