//
//  TwitchIRC.swift
//  Twitch Bot
//
//  Created by leon on 3/17/24.
//
import Foundation

class IRCClient {
    let host: String
    let port: Int
    var inputStream: InputStream!
    var outputStream: OutputStream!

    init(host: String, port: Int) {
        self.host = host
        self.port = port
    }

    func connect() {
        Stream.getStreamsToHost(withName: host, port: port, inputStream: &inputStream, outputStream: &outputStream)
        inputStream.delegate = self
        outputStream.delegate = self
        inputStream.schedule(in: .current, forMode: .default)
        outputStream.schedule(in: .current, forMode: .default)
        inputStream.open()
        outputStream.open()
    }

    func authenticate(username: String, oauthToken: String) {
        sendMessage("PASS oauth:\(oauthToken)")
        sendMessage("NICK \(username)")
    }

    func join(channel: String) {
        sendMessage("JOIN \(channel)")
    }

    func sendMessage(_ message: String) {
        let data = "\(message)\r\n".data(using: .utf8)!
        _ = data.withUnsafeBytes { outputStream.write($0.bindMemory(to: UInt8.self).baseAddress!, maxLength: data.count) }
    }

    func listen() {
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 1024)
        var message = ""

        while inputStream.hasBytesAvailable {
            let bytesRead = inputStream.read(buffer, maxLength: 1024)

            if bytesRead > 0 {
                if let receivedString = String(bytesNoCopy: buffer, length: bytesRead, encoding: .utf8, freeWhenDone: true) {
                    message += receivedString
                }

                // Check if the message contains a newline character
                if message.contains("\r\n") {
                    let components = message.components(separatedBy: "\r\n")
                    for component in components {
                        handleIncomingMessage(component)
                    }
                    // Reset message for the next iteration
                    message = ""
                }
            } else {
                break // No more bytes available
            }
        }
    }

    func handleIncomingMessage(_ message: String) {
        if message.hasPrefix("PING") {
            respondToPing()
        } else {
            print(message)
        }
    }

    func respondToPing() {
        sendMessage("PONG :tmi.twitch.tv")
    }
}

extension IRCClient: StreamDelegate {
    func isEqual(_ object: Any?) -> Bool {
        return false
    }
    
    var hash: Int {
        return 0
    }
    
    var superclass: AnyClass? {
        return nil
    }
    
    func `self`() -> Self {
        return self
    }
    
    func perform(_ aSelector: Selector!) -> Unmanaged<AnyObject>! {
        return nil
    }
    
    func perform(_ aSelector: Selector!, with object: Any!) -> Unmanaged<AnyObject>! {
        return nil
    }
    
    func perform(_ aSelector: Selector!, with object1: Any!, with object2: Any!) -> Unmanaged<AnyObject>! {
        return nil
    }
    
    func isProxy() -> Bool {
        return false
    }
    
    func isKind(of aClass: AnyClass) -> Bool {
        return false
    }
    
    func isMember(of aClass: AnyClass) -> Bool {
        return false
    }
    
    func conforms(to aProtocol: Protocol) -> Bool {
        return false
    }
    
    func responds(to aSelector: Selector!) -> Bool {
        return false
    }
    
    var description: String {
        return ""
    }
    
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case .hasBytesAvailable:
            if aStream == inputStream {
                listen()
            }
        default:
            break
        }
    }
}

func handleTwitch() throws {
    // Create an instance of TwitchChat
    let host = "irc.chat.twitch.tv"
    let port = 6667

    // Twitch username and OAuth token (replace with your own)
    let username = "SkyEyeBot"
    let oauthToken = "oauth:0vketpwjlflxtfoiwgs9840yfmqmbg"

    // Twitch channel to join
    let channel = "#imbestcaptain"

    // Create an instance of IRCClient
    let ircClient = IRCClient(host: host, port: port)

    // Connect to Twitch IRC server
    ircClient.connect()

    // Authenticate with Twitch IRC
    ircClient.authenticate(username: username, oauthToken: oauthToken)

    // Join the Twitch channel
    ircClient.join(channel: channel)
    
    // Run the run loop to allow delegate methods to be called
    RunLoop.current.run()
}

