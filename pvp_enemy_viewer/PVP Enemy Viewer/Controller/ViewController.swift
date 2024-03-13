//
//  ViewController.swift
//  PVP Enemy Viewer
//
//  Created by leon on 3/12/24.
//

import Cocoa

class ViewController: NSViewController {
    
    @IBOutlet weak var capTxtField: NSTextField!
    @IBOutlet weak var nmTxtField: NSTextField!
    @IBOutlet weak var modePopUpBtn: NSPopUpButton!
    
    
    @IBOutlet weak var stateLabel: NSTextField!
    var bpView: BattlePlanView?
    
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
    
    @IBAction func fetchClicked(_ sender: NSButton) {
        
        let enemyName = nmTxtField.stringValue
        bpView?.removeFromSuperview()
        self.drawEnemyMap(enemyName: enemyName)
    }
    
    var canFetch = false
    var fetchTimer: Timer?

    @IBAction func autoFetchClicked(_ sender: Any) {
        let enemyName = nmTxtField.stringValue
        
        if canFetch {
            stateLabel.layer?.backgroundColor = NSColor.clear.cgColor
            canFetch = false
            fetchTimer?.invalidate()
            fetchTimer = nil
            bpView?.removeFromSuperview()
        }
        else {
            stateLabel.layer?.backgroundColor = NSColor.green.cgColor
            canFetch = true
            fetchTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                self.bpView?.removeFromSuperview()
                if self.canFetch {
                    self.drawEnemyMap(enemyName: enemyName)
                } else {
                    self.fetchTimer?.invalidate()
                    self.fetchTimer = nil
                    
                }
            }
        }
        bpView?.removeFromSuperview()
    }
    
    @IBAction func updateClicked(_ sender: Any) {
        updateGameData()
    }
    
    @IBAction func joinClicked(_ sender: Any) {
        let gameMode = modePopUpBtn.selectedItem!.title
        let enemyName = nmTxtField.stringValue
        joinCaptain(enemyName: enemyName, gameMode: gameMode)
    }
    
    @IBAction func leaveClicked(_ sender: Any) {
        leaveCaptain()
    }
    
    @IBAction func clearClicked(_ sender: Any) {
        bpView?.removeFromSuperview()
    }
    
    func drawEnemyMap(enemyName: String) {
        
        bpView?.removeFromSuperview()
        
        fetchEnemyData(enemyName: enemyName) { result in
            
            self.bpView?.setNeedsDisplay(self.bpView!.bounds)
            
            let width = result.0
            let height = result.1
            if width == 0.0 || height == 0.0 {
                return
            }
            let allyZones = result.2
            let neutralZones = result.3
            let purpleZones = result.4
            let enemyZones = result.5
            let markers = result.6
            var captain: Captain
            if !result.7.isEmpty {
                captain = result.7[0]
            } else {
                captain = Captain(unit: "", x: 1000.0, y: 1000.0, width: 0.0, height: 0.0)
            }

            self.capTxtField.stringValue = captain.unit
            
            let cartesianPlaneSize = CGSize(width: width, height: height)
            let originX = (self.view.bounds.width - cartesianPlaneSize.width) / 2
            let originY = (self.view.bounds.height - cartesianPlaneSize.height) / 2
            let cartesianPlaneFrame = CGRect(origin: CGPoint(x: originX, y: originY), size: cartesianPlaneSize)
            let bpView = BattlePlanView(frame: cartesianPlaneFrame)
            
            bpView.width = width
            bpView.height = height
            
            bpView.captain = captain
            var allZones = [Any]()
            allZones.append(contentsOf: allyZones)
            allZones.append(contentsOf: purpleZones)
            allZones.append(contentsOf: neutralZones)
            
            bpView.zones = NSArray(array: allZones)
            bpView.enemyZones = NSArray(array: enemyZones)
            bpView.markers = markers
            
            self.bpView = bpView
            self.view.addSubview(bpView)
            bpView.setNeedsDisplay(bpView.bounds)
            
        }
    }
    
}

class BattlePlanView: NSView {
    
    var width: Double = 0.0
    var height: Double = 0.0
    var scale: CGFloat = 15
    var captain: Captain = Captain(unit: "", x: 0.0, y: 0.0, width: 0, height: 0)
    var zones: NSArray?
    var enemyZones: NSArray?
    var markers: [Marker] = []
    
    override func resize(withOldSuperviewSize oldSize: NSSize) {
            super.resize(withOldSuperviewSize: oldSize)
            self.setNeedsDisplay(self.bounds)
        }
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        context.clear(bounds)
        context.scaleBy(x: scale, y: scale)
        
        //Draw zones
        func drawZones(_ zones: [[String: Any]], fillColor: NSColor) {
            for zone in zones {
                if let x = zone["x"] as? Double,
                   let y = zone["y"] as? Double,
                   let width = zone["width"] as? Double,
                   let height = zone["height"] as? Double {
                    let zoneRect = CGRect(x: CGFloat(x), y: CGFloat(y), width: CGFloat(width), height: CGFloat(height))
                    context.setFillColor(fillColor.cgColor)
                    context.fill(zoneRect)
                }
            }
        }
        
        //Draw zones zones
        if let zones = zones as? [[String: Any]] {
            drawZones(zones, fillColor: NSColor(red: 1.0, green: 0.5, blue: 0.5, alpha: 0.2))
        }
        
        //Draw ally zones
        if let enemyZones = enemyZones as? [[String: Any]] {
            drawZones(enemyZones, fillColor: NSColor(red: 0.5, green: 0.5, blue: 1.0, alpha: 0.2))
        }
        
        //Draw markers
        for marker in markers {
            let iconImage = #imageLiteral(resourceName: marker.icon)
            let iconSize: CGFloat = 0.8
            let iconRect = CGRect(x: CGFloat(marker.x) - iconSize / 2, y: CGFloat(marker.y) - iconSize / 2, width: iconSize, height: iconSize)
            iconImage.draw(in: iconRect)
        }
        
        //Draw enemy captain
        let capX = CGFloat(captain.x)
        let capY = CGFloat(captain.y)
        let dotSize: CGFloat = 0.7
        let dotRect = CGRect(x: capX - dotSize / 2, y: capY - dotSize / 2, width: dotSize, height: dotSize)
        let dotPath = NSBezierPath(ovalIn: dotRect)
        NSColor.purple.setFill()
        dotPath.fill()
    }
}
