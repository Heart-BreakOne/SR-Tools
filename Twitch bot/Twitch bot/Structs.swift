//
//  Structs.swift
//  Twitch bot
//
//  Created by leon on 3/16/24.
//

import Foundation

struct Datum {
    let code: String
    let commands: [String]
    let phrases: [String]
    let watchList: [String]
    let blocklist: [String]
    let log: Log
}

struct Log {
    let event: Int
    let capName: String
    let scale: Int
    let qttPlayers: Int
    let enmPlayers: Int
    let power: Int
    let enmPower: Int
    let spell: String
    let enmSpell: String
    let unit: String
    let enmunit: String
    let outcome: String
    
}
