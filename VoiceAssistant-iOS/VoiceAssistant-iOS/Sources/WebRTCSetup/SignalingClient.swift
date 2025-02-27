//
//  SignalingClient.swift
//  VoiceAssistant
//
//  Created by Shivansh Gaur on 13/12/24.
//

import WebRTC
import AVFoundation

// MARK: - SignalingDelegate Protocol
/// Protocol to notify when the socket is connected and audio starts.
protocol SignalingDelegate: AnyObject {
    func socketConnectionStatus(connected: Bool)
//    func didStartedAudioCall()
    func botSpeakingStatus(isSpeaking: Bool)
    func signalingDidReceiveMessage(message: String)
}

class Signaling: NSObject {
    var webSocketManager: WebSocketManager
    var webRTCManager: WebRTCManager
    
    weak var delegate: SignalingDelegate?
    var audioPlayer: AVAudioPlayer?
    private var isOnHold: Bool = false
    private var isRingerPlaying: Bool = false
    private var packIDCreated: String = ""
    
    override init() {
        webRTCManager = WebRTCManager()
        webSocketManager = WebSocketManager(url: Constants.WebRTCCalls.serverURL)
        super.init()
        
        webSocketManager.onMessageReceived = { [weak self] message in
            self?.handleSignalingMessage(message)
        }
        
        webSocketManager.socketConnectionStatus = { [weak self] connected in
            if connected {
                self?.delegate?.socketConnectionStatus(connected: true)
                self?.emitMessage(for: .login)
            } else {
                self?.stopRinger()
                self?.delegate?.socketConnectionStatus(connected: false)
                print("Socket Disconnected Received")
            }
        }
        
        webRTCManager.delegate = self
        webRTCManager.peerConnection?.delegate = webRTCManager
    }
    
    /// `Step 1 -` Call `connectSocket()` to get socket connected when framework init
    /// So we can send ASR Event ti start sending and receiveing audio
    func connectSocket() {
//        playRinger() /// Start Playing Ringer
        webRTCManager.setupConnection()
        webRTCManager.addAudioTrack()
    }
    
    /// `Step 2 -` Call `startCall()` to start Audio call
    /// It send ASR event to sending/receiving audio packets
    func startCall() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        emitMessage(for: .startAsr)
    }
    
    /// `Step 3 -` Call `endCall()` to start Audio call
    /// /// It send stop-ASR event to stop sending/receiving audio packets
    func endCall() {
        guard !isRingerPlaying else {
            stopRinger()
            return
        }
        
        // MARK: No Need to emit below messages in case websocket is not connected
        emitMessage(for: .stopAsr)
        emitMessage(for: .bye)
        cleanUp()
    }
    
    private func cleanUp() {
        DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        webRTCManager.peerConnection?.close()
        webSocketManager.disconnect()
    }
    
    func holdCall() {
        isOnHold ? emitMessage(for: .startAsr) : emitMessage(for: .stopAsr)
        isOnHold.toggle()
        webRTCManager.localAudioTrack?.isEnabled = !isOnHold
        webRTCManager.remoteAudioTrack?.isEnabled = !isOnHold
    }
    
    /// Play ringer until socket get connected
    func playRinger() {
        AudioSessionManager.shared.configureForPlayback()
        
        let frameworkBundle = Bundle(for: Signaling.self)
        if let url = frameworkBundle.url(forResource: "ringing", withExtension: "mp3") {
            
            do {
                // Initialize the audio player with the URL
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.prepareToPlay()
                audioPlayer?.numberOfLoops = -1
                audioPlayer?.play()
                isRingerPlaying = true
            } catch {
                print("Failed to Play Ringtone: \(error.localizedDescription)")
            }
        }
    }
    
    func stopRinger() {
        DispatchQueue.main.async {
            if let player = self.audioPlayer, player.isPlaying {
                player.stop()
                self.isRingerPlaying = false
                AudioSessionManager.shared.configureForAudioCall()
            }
//            self.delegate?.didStartedAudioCall()
        }
    }
    
    func handleSignalingMessage(_ message: String) {
        guard let data = message.data(using: .utf8) else {
            debugPrint("Failed to convert message to Data")
            return
        }
        
        // Attempt to parse the JSON as a dictionary to check the 'method' field
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
              let method = jsonObject["method"] as? String else {
            //            debugPrint("Invalid JSON format or missing 'method' field")
            return
        }
        
        switch method {
        case "verto.clientReady":
            webRTCManager.createOffer { offer in
                guard (offer != nil) else {
                    debugPrint("Failed to create offer")
                    return
                }
            }
            
        case "verto.answer":
            guard let params = jsonObject["params"] as? [String: Any],
                  let sdp = params["sdp"] as? String else {
                debugPrint("No Field with Remote SDP Received")
                return
            }
            
            let sessionDescription = RTCSessionDescription(type: .answer, sdp: sdp)
            webRTCManager.peerConnection?.setRemoteDescription(sessionDescription, completionHandler: { error in
                if let error = error {
                    print("Failed to set remote SDP: \(error.localizedDescription)")
                }
            })
            
        case "verto.display":
            if isRingerPlaying == true {
                stopRinger()
            }
            do {
                let displayMessage = try JSONDecoder().decode(MessageDisplayModel.self, from: data)
                handleDisplayMessage(displayMessage)
            } catch {
                print("Failed to decode MessageDisplayModel: \(error.localizedDescription)")
            }
            
        case "verto.bye":
            print("Bye received")
            cleanUp()
            
        default:
            print("Unhandled method: \(method)")
        }
    }
    
    func handleDisplayMessage(_ displayMessage: MessageDisplayModel) {
        let params = displayMessage.params
        
        guard let displayName = params.displayName else { print("Display Name: nil"); return }
        
        if let transcription = displayName.transcription {
            print("Transcription: \(transcription)")
            delegate?.signalingDidReceiveMessage(message: transcription)
        }
        
        if let asrEvent = displayName.eventName {
            let param = asrEvent == "play_start" ? true : false
            delegate?.botSpeakingStatus(isSpeaking:  param)
        }
        
        if let pageToNavigate = displayName.pageToNavigate {
            print("Page To Navigate: \(pageToNavigate)")
            VoiceAssistant.sendPageToNavigate(pageToNavigate)
            
            if pageToNavigate == "RechargeDetails-249" {
                packIDCreated = "2"
            } else if pageToNavigate == "RechargeDetails-449" {
                packIDCreated = "1"
            } else if pageToNavigate == "RechargeDetails-349" {
                packIDCreated = "3"
            }
            print("Pack ID Generated: \(packIDCreated)")
            
            if pageToNavigate.lowercased() == "Subscribe".lowercased() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.sendRechargeSuccess(for: self.packIDCreated)
                }
            }
        }
    }
    
    private func emitMessage(for event: MessageType) {
        var eventMessageString: [String: Any]?
        
        switch event {
        case .login:
            eventMessageString = Constants.WebRTCCalls.createLoginMessage()
        case .ping:
            eventMessageString = Constants.WebRTCCalls.sendPingResponse()
        case .startAsr:
            playRinger() /// Start Playing Ringer
            eventMessageString = Constants.WebRTCCalls.startASR(for: .startAsr)
        case .stopAsr:
            eventMessageString = Constants.WebRTCCalls.startASR(for: .stopAsr)
        case .bye:
            eventMessageString = Constants.WebRTCCalls.sendBye(for: .bye)
        }
        
        guard let eventMessageString else {
            debugPrint("Event Message for \(event.rawValue) found nil")
            return
        }
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: eventMessageString, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print("Emited Event: \(event.rawValue)")
            self.webSocketManager.send(message: jsonString)
        }
    }
    
    public func sendRechargeSuccess(for packID: String) {
        let eventMessageString = Constants.WebRTCCalls.sendRechargeSuccessEvent(with: packID)
        print("sendRechargeSuccess: \(eventMessageString)")
        if let jsonData = try? JSONSerialization.data(withJSONObject: eventMessageString, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            self.webSocketManager.send(message: jsonString)
        }
    }
}

extension Signaling: WebRTCDelegate {
    
    func isICEGenerated() {
        guard let localDescription = webRTCManager.peerConnection?.localDescription else { print("Local description is not set"); return }
        
//        let offerDict = Constants.WebRTCCalls.createOfferMessage(offer: sdp) // Not working
        let offerDict = Constants.WebRTCCalls.createOfferMessage(offer: localDescription.sdp)
        if let jsonData = try? JSONSerialization.data(withJSONObject: offerDict, options: []),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            self.webSocketManager.send(message: jsonString)
        }
    }
}
