import UIKit
import SwiftPhoenixClient

class ViewController: UIViewController {
    
    //----------------------------------------------------------------------
    // MARK: - Child Views
    //----------------------------------------------------------------------
    @IBOutlet var userField: UITextField!
    @IBOutlet var messageField: UITextField!
    @IBOutlet var chatWindow: UITextView!
    @IBOutlet var sendButton: UIButton!
  
    @IBOutlet weak var socketButton: UIButton!
    
   // var socket = Socket("ws://localhost:4000/socket/websocket")
    var topic: String = "chat:trialChat"
    var lobbyChannel: Channel!
    var token: String = ""
    var socket: Socket!
  
    override func viewDidLoad() {
        super.viewDidLoad()
        func getToken(){
            DispatchQueue.main.async {
                let tokenReq = tokenRequest()
                tokenReq.getToken{[weak self] result in
                    switch result{
                    case .failure(let error):
                        print(error)
                    case .success(let token2):
                        self?.token = token2
                        let url = "wss://api.sariska.io/api/v1/messaging/websocket?token="
                        self?.socket = Socket(url+token2)
                        self?.socket.delegateOnOpen(to: (self)!) { (self) in
                            self.addText("Socket Opened")
                            self.socketButton.setTitle("Disconnect", for: .normal)
                        }
                        self?.socket.delegateOnClose(to: (self)!) { (self) in
                            self.addText("Socket Closed")
                            self.socketButton.setTitle("Connect", for: .normal)
                        }
                        self?.socket.delegateOnError(to: (self)!) { (self, error) in
                        
                            self.addText("Socket Errored: " + error.localizedDescription)
                        }
                        self?.socket.logger = { msg in print("LOG:", msg) }
                    }
                }
            }
        }
        getToken()
    // To automatically manage retain cycles, use `delegate*(to:)` methods.
        // If you would prefer to handle them yourself, youcan use the same
        // methods without the `delegate` functions, just be sure you avoid
        // memory leakse with `[weak self]`
    }
    //----------------------------------------------------------------------
    // MARK: - IBActions
    //----------------------------------------------------------------------
    @IBAction func onSocketButtonPressed(_ sender: Any) {
        
        if socket.isConnected {
            disconnectAndLeave()
        } else {
            connectAndJoin()
        }
    }
    
    @IBAction func sendMessage(_ sender: UIButton) {
        let payload = ["user":userField.text!, "content": messageField.text!]
        
        self.lobbyChannel
            .push("new_message", payload: payload)
            .receive("ok") { (message) in
                print("success", message)
                self.addText(message.payload["content"] as! String)
            }
            .receive("error") { (errorMessage) in
                print("error: ", errorMessage)
        }
        
        self.addText(payload["content"]!)
        
        messageField.text = ""
    }
    
    //----------------------------------------------------------------------
    // MARK: - Private
    //----------------------------------------------------------------------
    private func disconnectAndLeave() {
        // Be sure the leave the channel or call socket.remove(lobbyChannel)
        lobbyChannel.leave()
        socket.disconnect {
            self.addText("Socket Disconnected")
        }
    }
    
    private func connectAndJoin() {
        let channel = socket.channel(topic, params: ["status":"joining"])
        
        channel.delegateOn("user_joined", to: self) { (self, _) in
            self.addText("You are here now.")
            self.addText("You joined the room.")
        }
        
        channel.delegateOn("new_message", to: self) { (self, message) in

            self.addText(message.payload["content"] as! String)
        }
        
        
        self.lobbyChannel = channel
        self.lobbyChannel
            .join()
            .delegateReceive("ok", to: self) { (self, _) in
                self.addText("Joined Channel")
            }.delegateReceive("error", to: self) { (self, message) in
                self.addText("Failed to join channel: \(message.payload)")
            }
        self.socket.connect()
        
    }
    
    private func addText(_ text: String) {
        let updatedText = self.chatWindow.text.appending(text).appending("\n")
        self.chatWindow.text = updatedText
    }

}
