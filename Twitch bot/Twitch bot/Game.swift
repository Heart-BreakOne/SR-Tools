//
//  Game.swift
//  Twitch bot
//
//  Created by leon on 3/16/24.
//

import Foundation

let gameUrl = "https://www.streamraiders.com/api/game/"

func banUser(username: String, completion: @escaping (String) -> Void){
    
    let url = "\(gameUrl)?cn=setBanStatus&command=setBanStatus&twitchUserName=\(username)&isBanned=y"
    makeRequest(urlString: url) { _ in
        // No need to handle the response.
    }
    completion("Banned successfully :(")
}

func unbanUser(username: String, completion: @escaping (String) -> Void) {
    
    var json = getJson()
    let permalist = json["permalist"] as! [String]
    if permalist.contains(username) {
        completion("@\(username), can not unban you at this occasion")
        return
    }
    var watchlist = json["watchlist"] as! [String]
    watchlist.append(username)
    json["watchlist"] = watchlist
    updateJson(json: json)
    
    
    let bannedUrl = "\(gameUrl)?cn=getBanList&command=getBanList"
    var completionString = ""
    
    makeRequest(urlString: bannedUrl) { data in
        guard let data = data else {
            completion("Unable to fetch ban list.")
            return
        }

        do {
            if let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                let status = dict["status"] as! String

                if status != "success" {
                    completion("Unable to fetch ban list.")
                    return
                }

                let usersList = dict["data"] as! [String: Any]
                let banList = usersList["bans"] as! [[String: Any]]

                for banned in banList {
                    guard let ban = banned as? [String: Any], !ban.isEmpty else {
                        continue
                    }

                    let name = banned["twitchUserName"] as! String

                    if username.lowercased() == name.lowercased() {
                        let userId = banned["userId"] as! String
                        let banUrl = "\(gameUrl)?cn=setBanStatus&command=setBanStatus&userId=\(userId)&twitchUserName=\(username)&isBanned=n"
                        
                        makeRequest(urlString: banUrl) { _ in
                            completionString = "@\(username) you have been unbanned, the captain should be visible after this battle. But be warned, tank souls, spies and erasing tactical markers may grant you a new permanent ban for being a repeat offender."
                            completion(completionString)
                        }
                        return // Return here to avoid calling completion prematurely
                    }
                }

                // If the loop completes without finding the username
                completion("@\(username), you are not banned. Check if you typed the username correctly! Try reloading the game")
            }
        } catch {
            print("Error decoding data: \(error)")
            completion("Error decoding ban list.")
        }
    }
}


func makeRequest(urlString: String, completion: @escaping ((Data?) -> Void)) {
    let (token, _) = getUserData()
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
