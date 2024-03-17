//
//  Twitch.swift
//  Twitch bot
//
//  Created by leon on 3/16/24.
//

import Foundation

//Log battle
func logBattle(eventId: String, captainName: String, scale: String, qttPlayers: String, enmPlayers: String, power: String, enmPower: String, spell: String, enmSpell: String, unit: String, enmUnit: String, outcome: String) -> String {
    
    let dataToLog = ["event": eventId, "capName": captainName, "scale": scale, "qttPlayers": qttPlayers, "enmPlayers": enmPlayers, "power": power, "enmPower": enmPower, "spell": spell, "enmSpell": enmSpell, "unit": unit, "enmunit": enmUnit, "outcome": outcome] as [String : Any]
    var json = getJson()
    var log = json["log"] as! [[String: Any]]
    log.insert(dataToLog, at: 0)
    json["log"] = log
    updateJson(json: json)
    return "Logged!"
}

//List commands
func sendCommands() -> String {
    let json = getJson()
    let commands = json["chatCommands"] as! [String]
    var commandsStr = "Commands available are: "
    for com in commands {
        commandsStr = commandsStr + com
    }
    return commandsStr
}

//Send current winning streak
func sendStreak() -> String {
    let json = getJson()
    let battleLog = json["log"] as! [[String: Any]]
    var streakCounter = 0
    for log in battleLog {
        if log["outcome"] as! String == "win" {
            streakCounter += 1
        } else {
            break
        }
    }
    return "The current win streak is \(streakCounter)"
}

// Set battle code
func setCode(code: String) -> String {
    var json = getJson()
    json["code"] = code
    updateJson(json: json)
    return "New code has been set DoritosChip"
}

//Send code if there's any
func sendCode() -> String {
    let json = getJson()
    let code = json["code"] as! String
    if code == "none" {
        return "No code at the moment"
    } else {
        return "Code is \(code). Please follow the markers, no tank souls, no spies, do not erase tactical markers with wrong placements."
    }
}

//Send random message related to the PVP box strategy
func sendBox() -> String {
    let json = getJson()
    let msg = json["phrases"] as! [String]
    let randomMsg = msg.randomElement()!
    return randomMsg
}

//Add unbanned users to watch list
func addWatchList(username: String) -> String{
    updateList(username: username, listId: "watchlist")
    return "Watchlist updated successfully!"
}

//Prevent users from unbanning themselves
func addPermaList(username:String) -> String {
    updateList(username: username, listId: "permalist")
    return "Permalist updated successfully!"
}

func updateList(username:String, listId: String) {
    var json = getJson()
    var list = json[listId] as! [String]
    
    list.append(username)
    json[listId] = list
    updateJson(json: json)
    
}

//Play audio cue to start battle
func playBattle() {
    
    let process = Process()
    process.launchPath = "/usr/bin/say"
    process.arguments = ["Come back here and start your battle."]
    process.launch()
    process.waitUntilExit()
}

// Check battle stats
func checkStats(from: String) -> String{
    var stats = ""
    let json = getJson()
    let battleLog = json["log"] as! [[String: Any]]
    switch from {
    case "":
        stats = getAllStats(battleLog: battleLog)
    case "current":
        stats = getCurrentStats(battleLog: battleLog)
    default:
        stats = getCaptainStats(from: from, battleLog: battleLog)
    }
    
    return stats
}

func getAllStats(battleLog: [[String: Any]]) -> String {
    var wins = 0
    var losses = 0
    for b in battleLog {
        let outcome = b["outcome"] as! String
        if outcome == "win" {
            wins += 1
        } else if outcome == "loss" {
            losses += 1
        }
    }
    let total = wins + losses
    let winRate = Int(Double(wins) / Double(total) * 100.0)
    return "Historical stats: \(wins) battles won, \(losses) battles lost, \(winRate)% winning rate."
}

func getCurrentStats(battleLog: [[String: Any]]) -> String{
    var wins = 0
    var losses = 0
    for b in battleLog {
        if b["event"] as! Int == 1 {
            let outcome = b["outcome"] as! String
            if outcome == "win" {
                wins += 1
            } else if outcome == "loss" {
                losses += 1
            }
        }
    }
    let total = wins + losses
    let winRate = Int(Double(wins) / Double(total) * 100.0)
    return "Current event stats: \(wins) battles won, \(losses) battles lost, \(winRate)% winning rate."
}

func getCaptainStats(from: String, battleLog: [[String: Any]]) -> String{
    var wins = 0
    var losses = 0
    for b in battleLog {
        let capName = b["capName"] as! String
        if capName.lowercased() == from.lowercased() {
            let outcome = b["outcome"] as! String
            if outcome == "win" {
                wins += 1
            } else if outcome == "loss" {
                losses += 1
            }
        }
    }
    
    if wins == 0 && losses == 0 {
        return "No data to show."
    } else {
        let total = wins + losses
        let winRate = Int(Double(wins) / Double(total) * 100.0)
        return "Historical stats against \(from): \(wins) battles won, \(losses) battles lost, \(winRate)% winning rate."
    }
}
