//
//  TokenViewerController.swift
//  PVP Enemy Viewer
//
//  Created by leon on 3/12/24.
//

import Cocoa

class TokenViewerController: NSViewController {
    
    @IBOutlet weak var tokenTxtField: NSTextField!
    
    @IBOutlet weak var confTxtField: NSTextField!
    
    
    override func viewDidLoad() {
  
        if let t = UserDefaults.standard.object(forKey: "token") as! String? {
            tokenTxtField.stringValue = t
        }
    }
    
    @IBAction func saveBtnCliked(_ sender: Any) {
        
        confTxtField.stringValue = ""
        let token = tokenTxtField.stringValue
        
        UserDefaults.standard.setValue(token, forKey: "token")
        UserDefaults.standard.synchronize()
        
        confTxtField.stringValue = "Saved token successfully!"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.confTxtField.stringValue = ""
        }
    }
}
