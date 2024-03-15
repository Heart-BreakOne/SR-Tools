//
//  ViewController.swift
//  PVP Live Captains
//
//  Created by leon on 3/14/24.
//

import Cocoa

class ViewController: NSViewController {
    
    @IBOutlet weak var captainsLabel: NSTextField!
    @IBOutlet weak var stateLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        stateLabel.wantsLayer = true
        // Do any additional setup after loading the view.
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    @IBAction func fetchClicked(_ sender: Any) {
        getCaptains()
    }
    
    @IBAction func updateClicked(_ sender: NSButton) {
        updateGameData()
    }
    var canFetch = false
    var fetchTimer: Timer?
    @IBAction func autoFetchClicked(_ sender: Any) {
        if canFetch {
            stateLabel.layer?.backgroundColor = NSColor.clear.cgColor
            canFetch = false
            fetchTimer?.invalidate()
            fetchTimer = nil
        }
        else {
            stateLabel.layer?.backgroundColor = NSColor.green.cgColor
            canFetch = true
            fetchTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                if self.canFetch {
                    self.getCaptains()
                } else {
                    self.fetchTimer?.invalidate()
                    self.fetchTimer = nil
                    
                }
            }
        }
    }
    
    func getCaptains() {
        captainsLabel.stringValue = ""
        getLiveCaptainsData { string in
            DispatchQueue.main.async {
                self.captainsLabel.stringValue = string
            }
        }
    }
}

