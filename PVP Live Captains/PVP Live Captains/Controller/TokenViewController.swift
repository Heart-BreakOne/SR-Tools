//
//  TokenViewController.swift
//  PVP Live Captains
//
//  Created by leon on 3/14/24.
//

import Cocoa


class TokenViewController: NSViewController {
    

    @IBOutlet weak var tokenTxtField: NSTextField!
    
    @IBOutlet weak var confLabel: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        let tString = UserDefaults.standard.value(forKey: "token") as? String ?? ""
        tokenTxtField.stringValue = tString
    }
    

    @IBAction func saveClicked(_ sender: NSButton) {
        let t = tokenTxtField.stringValue
        UserDefaults.standard.setValue(t, forKey: "token")
        UserDefaults.standard.synchronize()
        confLabel.stringValue = "Saved successfully!"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.confLabel.stringValue = ""
        }
    }
}
