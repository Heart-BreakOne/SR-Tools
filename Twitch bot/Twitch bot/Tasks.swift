//
//  Tasks.swift
//  Twitch bot
//
//  Created by leon on 3/16/24.
//

import Foundation

func updateUserData() {
    if UserDefaults.standard.value(forKey: "twitchToken") is String {
        print("Token already exists, starting chat bot...")
    } else {
        print("Insert Twitch token:")
        if let token = readLine(), !token.isEmpty {
            UserDefaults.standard.set(token, forKey: "twitchToken")
            UserDefaults.standard.synchronize()
        }
        print("Insert SR token:")
        if let srToken = readLine(), !srToken.isEmpty {
            UserDefaults.standard.set(srToken, forKey: "srToken")
            UserDefaults.standard.synchronize()
        }
    }
}

func deleUserData() {
    UserDefaults.standard.removeObject(forKey: "twitchToken")
    UserDefaults.standard.removeObject(forKey: "srToken")
    UserDefaults.standard.synchronize()
    print("Deleted your tokens successfully!")
}

func getUserData() -> (String, String) {
    
    let token = UserDefaults.standard.object(forKey: "srToken")! as! String
    let twitchToken = UserDefaults.standard.object(forKey: "twitchToken") as! String
    return ("ACCESS_INFO=\(token)", twitchToken)
    
}

func getJson() -> [String: Any] {
    
    let filePath = "/Users/leonardoluiz/dev/SR-Tools/Twitch bot/Twitch bot/Assets/data.json"
    let url = URL(fileURLWithPath: filePath)
    do {
        // Read the contents of the file
        let data = try Data(contentsOf: url)
        
        // Parse the JSON data
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        
        // Handle the JSON object as needed
        return json as! [String: Any]
    } catch {
        print("Error: Unable to read or parse the JSON file - \(error)")
    }
    return [:]
}



func updateJson(json: [String: Any]) {
    let filePath = "/Users/leonardoluiz/dev/SR-Tools/Twitch bot/Twitch bot/Assets/data.json"
    let url = URL(fileURLWithPath: filePath)
    do {
        let jsonData = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted])
        try jsonData.write(to: url)
        print("JSON data has been updated and saved.")
    } catch {
        print("Error: Unable to update and save the JSON data - \(error)")
    }
}
