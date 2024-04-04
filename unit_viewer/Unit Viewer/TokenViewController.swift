import Cocoa

class TokenViewController: NSViewController, NSTextFieldDelegate {

    @IBOutlet weak var confTextField: NSTextField!
    @IBOutlet weak var tokenTextField: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        tokenTextField.delegate = self
    }

    @IBAction func saveToken(_ sender: NSButton) {
        let tokenString = tokenTextField.stringValue
        UserDefaults.standard.setValue(tokenString, forKey: "accessInfo")
        UserDefaults.standard.synchronize()
        confTextField.stringValue = "Saved token successfully!"
        tokenTextField.stringValue = ""
    }
}
