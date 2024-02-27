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
}

func deleteUserData(){
        UserDefaults.standard.removeObject(forKey: "accessInfo")
    
        UserDefaults.standard.synchronize()
        print("Data cleared successfully.")
}
