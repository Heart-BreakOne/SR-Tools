//
//  Structs.swift
//  PVP Live Captains
//
//  Created by leon on 3/14/24.
//

import Foundation

struct CaptainData {
    let isLive: String
    let raidState: Int
    let twitchDisplayName: String

    init?(json: [String: Any]) {
        guard let isLive = json["isLive"] as? String,
              let raidState = json["raidState"] as? Int,
              let twitchDisplayName = json["twitchDisplayName"] as? String else {
            return nil
        }

        self.isLive = isLive
        self.raidState = raidState
        self.twitchDisplayName = twitchDisplayName
    }
}
