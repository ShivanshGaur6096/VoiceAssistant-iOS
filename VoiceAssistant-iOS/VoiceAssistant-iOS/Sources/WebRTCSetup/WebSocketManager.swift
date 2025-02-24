//
//  WebSocketManager.swift
//  VoiceAssistant
//
//  Created by Shivansh Gaur on 13/12/24.
//

import Foundation

class WebSocketManager: NSObject {
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession!
    
    var onMessageReceived: ((String) -> Void)?
    var socketConnectionStatus: ((Bool) -> Void)?
    
    // Keep the receive task alive
    private var isConnected = false
    
    init(url: String) {
        super.init()
        let urlRequest = URLRequest(url: URL(string: url)!)
        let configuration = URLSessionConfiguration.default
        urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        connect(urlRequest: urlRequest)
    }
    
    // MARK: - Connection Methods
    private func connect(urlRequest: URLRequest) {
        webSocketTask = urlSession.webSocketTask(with: urlRequest)
        webSocketTask?.resume()
        isConnected = true
        socketConnectionStatus?(true)
        receiveMessage()
    }
    
    func disconnect() {
        isConnected = false
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        socketConnectionStatus?(false)
    }
    
    func send(message: String) {
        let wsMessage = URLSessionWebSocketTask.Message.string(message)
        webSocketTask?.send(wsMessage) { error in
            if let error = error {
                print("WebSocket sending error: \(error.localizedDescription)")
            }
//            else {
//                print("WebSocket message sent: \(message)")
//            }
        }
    }
    
    private func receiveMessage() {
        guard isConnected else { return }
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                print("WebSocket receiving error: \(error.localizedDescription)")
                self.socketConnectionStatus?(false)
                // Optionally, attempt to reconnect
            case .success(let message):
                switch message {
                case .string(let text):
//                    print("Received Text message: \(text)")
                    self.onMessageReceived?(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
//                        print("Received data message: \(text)")
                        self.onMessageReceived?(text)
                    } else {
                        print("Received binary data which couldn't be decoded to string.")
                    }
                @unknown default:
                    print("Received unknown message type.")
                }
                
                // Continue listening for the next message
                self.receiveMessage()
            }
        }
    }
    
    // MARK: - Reconnection Logic (Optional)
    func reconnect(url: String) {
        disconnect()
        DispatchQueue.global().asyncAfter(deadline: .now() + 5) { // Reconnect after 5 seconds
            let urlRequest = URLRequest(url: URL(string: url)!)
            self.connect(urlRequest: urlRequest)
        }
    }
}

extension WebSocketManager: URLSessionWebSocketDelegate {
    
    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didOpenWithProtocol protocol: String?) {
//        print("WebSocket connected with protocol: \(String(describing: `protocol`))")
        socketConnectionStatus?(true)
    }
    
    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
                    reason: Data?) {
        print("WebSocket disconnected with close code: \(closeCode)")
        socketConnectionStatus?(false)
        
// Optionally, attempt to reconnect
//        if isConnected {
//            reconnect(url: webSocketTask.currentRequest?.url?.absoluteString ?? "")
//        }
    }
}

