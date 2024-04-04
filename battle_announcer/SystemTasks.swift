//
//  SystemTasks.swift
//  battle announcer
//
//  Created by leon on 2/22/24.
//

import Foundation

func checkUserDefaults(){
    let t = "accessInfo"
    if UserDefaults.standard.object(forKey: t) == nil {
        print("Please insert the ACCESS_INFO token string: ")
        let tInput = readLine()
        UserDefaults.standard.set(tInput, forKey: t)
        UserDefaults.standard.synchronize()
    } else {
        print("Token already exists.")
    }
    
    let u = "tUsername"
    if UserDefaults.standard.object(forKey: u) == nil {
        print("Please insert your twitch username: ")
        let uInput = readLine()
        UserDefaults.standard.set(uInput?.lowercased(), forKey: u)
        UserDefaults.standard.synchronize()
    } else {
        print("Username already exists.")
    }
    
    let o = "oldCreationDate"
    if UserDefaults.standard.object(forKey: o) == nil {
        UserDefaults.standard.set("", forKey: o)
        UserDefaults.standard.synchronize()
    } else {
        //Nothing to do when the data already exists
    }
}

func playTTS(ttsString: String) {
    let process = Process()
        process.launchPath = "/usr/bin/say"
        process.arguments = [ttsString]
        process.launch()
        process.waitUntilExit()
}

func deleteUserData(){
        UserDefaults.standard.removeObject(forKey: "accessInfo")
        UserDefaults.standard.removeObject(forKey: "oldCreationDate")
        UserDefaults.standard.removeObject(forKey: "tUsername")
    
        UserDefaults.standard.synchronize()
        print("Data cleared successfully.")
}
