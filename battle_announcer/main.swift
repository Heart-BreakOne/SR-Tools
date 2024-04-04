//
//  main.swift
//  battle announcer
//
//  Created by leon on 2/21/24.
//

import Foundation

func main() {
    print("Press ENTER to execute the battle announcer.\nType \"clean\" and press ENTER to delete your token information.\nType \"exit\" and press ENTER to exit the application.")
    let uI = readLine()
    switch uI {
    case "exit":
        exit(0)
    case "clean":
        deleteUserData()
    default:
        print("Starting the Battle Announcer")
    }
    
    checkUserDefaults()
    
    while true {
        do {
            try checkBattle()
            sleep(5)
        } catch {
            print("An error occurred:", error)
        }
    }
}

main()
