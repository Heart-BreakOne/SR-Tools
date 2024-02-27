
import Cocoa


var unitTypeColorArray: [(String, NSColor)] = []
class ViewController: NSViewController, NSTableViewDataSource {
    

    @IBOutlet weak var unitLabel: NSTextField!
    var cartesianPlaneView: CartesianPlaneView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @IBAction func fetchEnemyUnits(_ sender: NSButton) {
        var accessInfo: String = ""
        if let s = UserDefaults.standard.object(forKey: "accessInfo") as? String {
            accessInfo = s
        }
        let group = DispatchGroup()
        group.enter()
        getEnemyUnits(accessInfo: accessInfo) { mapWidth, mapHeight, placements in
            DispatchQueue.main.async {
                let cartesianPlaneSize = CGSize(width: 800, height: 600)
                let originX = (self.view.bounds.width - cartesianPlaneSize.width) / 2
                let originY = (self.view.bounds.height - cartesianPlaneSize.height) / 2
                let cartesianPlaneFrame = CGRect(origin: CGPoint(x: originX, y: originY), size: cartesianPlaneSize)
                let cartesianPlaneView = CartesianPlaneView(frame: cartesianPlaneFrame)
                
                cartesianPlaneView.mapWidth = mapWidth
                cartesianPlaneView.mapHeight = mapHeight
                cartesianPlaneView.placements = placements
                
                self.cartesianPlaneView = cartesianPlaneView
                self.view.addSubview(cartesianPlaneView)
                cartesianPlaneView.setNeedsDisplay(cartesianPlaneView.bounds)
                
                group.leave()
                
                self.addCaption()
            }
        }
        
        group.notify(queue: .main) {
            self.addCaption()
        }
    }
    
    func addCaption() {
        if (unitTypeColorArray.count == 0) {
            return
        }
        
        let attributedString = NSMutableAttributedString()
        for unit in unitTypeColorArray {
            let nameAttributedString = NSAttributedString(string: "■ \(unit.0)", attributes: [.foregroundColor: unit.1])
            attributedString.append(nameAttributedString)
            attributedString.append(NSAttributedString(string: "\n"))
        }

        unitLabel.attributedStringValue = attributedString
        
    }
}

class CartesianPlaneView: NSView {
    
    var placements: [PlacementDatum] = []
    var mapWidth: Int = 0
    var mapHeight: Int = 0
    var unitTypeColors: [String: NSColor] = [:]
    let scale: CGFloat = 1.0
    
    override func draw(_ rectangle: NSRect) {
        super.draw(rectangle)
        
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        NSColor.clear.setFill()
        context.fill(bounds)
        
        let scaleX = bounds.width / CGFloat(mapWidth) / scale
        let scaleY = bounds.height / CGFloat(mapHeight) / scale
        let scaledWidth = bounds.width / scale
        let scaledHeight = bounds.height / scale
        let halfScaledWidth = scaledWidth / 2
        let halfScaledHeight = scaledHeight / 2
        let centeredX = bounds.midX
        let centeredY = bounds.midY
        
        var groupedDots: [String: [CGPoint]] = [:]
        
        for placement in placements {
            let unitType = placement.CharacterType
            let x = CGFloat(placement.X) * scaleX
            let y = CGFloat(placement.Y) * scaleY
            
            let dotPosition = CGPoint(x: centeredX + x, y: centeredY + y)
            if var dots = groupedDots[unitType] {
                dots.append(dotPosition)
                groupedDots[unitType] = dots
            } else {
                groupedDots[unitType] = [dotPosition]
            }
        }
        
        NSColor.white.setFill()
        context.fill(bounds)
        
        context.setStrokeColor(NSColor.black.cgColor)
        context.setLineWidth(2.0)
        context.stroke(bounds)
    
        context.setStrokeColor(NSColor.black.cgColor)
        context.setLineWidth(2.0)
        
        context.move(to: CGPoint(x: centeredX - halfScaledWidth, y: centeredY))
        context.addLine(to: CGPoint(x: centeredX + halfScaledWidth, y: centeredY))
        context.strokePath()

        context.move(to: CGPoint(x: centeredX, y: centeredY - halfScaledHeight))
        context.addLine(to: CGPoint(x: centeredX, y: centeredY + halfScaledHeight))
        context.strokePath()
        
        let dotSize = scale * 6
        unitTypeColorArray = []
        for (unitType, dots) in groupedDots {
            let color = colorForUnitType(unitType)
            unitTypeColors[unitType] = color // Update color dictionary
            unitTypeColorArray.append((unitType, color))
            color.setFill()
            
            for dotPosition in dots {
                let dotRect = CGRect(x: dotPosition.x - dotSize / 2, y: dotPosition.y - dotSize / 2, width: dotSize, height: dotSize)
                context.fillEllipse(in: dotRect)
            }
        }
    }
    
    func colorForUnitType(_ unitType: String) -> NSColor {
        if let color = unitTypeColors[unitType] {
            return color
        } else {
            let randomColor = generateRandomColor()
            unitTypeColors[unitType] = randomColor
            return randomColor
        }
    }
    
    func generateRandomColor() -> NSColor {
        let red = CGFloat.random(in: 0...1)
        let green = CGFloat.random(in: 0...1)
        let blue = CGFloat.random(in: 0...1)
        return NSColor(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
