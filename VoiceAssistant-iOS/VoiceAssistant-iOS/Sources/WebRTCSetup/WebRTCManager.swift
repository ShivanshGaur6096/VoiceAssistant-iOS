//
//  WebRTCManager.swift
//  VoiceAssistant
//
//  Created by Shivansh Gaur on 13/12/24.
//

import WebRTC

protocol WebRTCDelegate: AnyObject {
    func isICEGenerated(sdp: String)
}

class WebRTCManager: NSObject {
    var peerConnectionFactory: RTCPeerConnectionFactory
    var peerConnection: RTCPeerConnection?
    var localAudioTrack: RTCAudioTrack?
    var localAudioSender: RTCRtpSender?
    var remoteAudioTrack: RTCAudioTrack?
    weak var delegate: WebRTCDelegate?
    
    override init() {
        RTCPeerConnectionFactory.initialize()
        peerConnectionFactory = RTCPeerConnectionFactory()
        super.init()
    }
    
    func setupConnection() {
        let config = RTCConfiguration()
        config.iceServers = [
            RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])
        ]
        
        // Optional: Adjust ICE transport policy
        config.iceTransportPolicy = .all // or .relay if you want to force TURN
        
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: ["DtlsSrtpKeyAgreement": "true"])
        peerConnection = peerConnectionFactory.peerConnection(with: config, constraints: constraints, delegate: self)
    }
    
    func addAudioTrack() {
        let audioSource = peerConnectionFactory.audioSource(with: RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil))
        localAudioTrack = peerConnectionFactory.audioTrack(with: audioSource, trackId: "audio0")
        localAudioSender = peerConnection?.add(localAudioTrack!, streamIds: ["stream0"])
    }
}

// Creating Local SDP and ending to Server after ICE has been generated
extension WebRTCManager {
    
    func createOffer(completion: @escaping (RTCSessionDescription?) -> Void) {
        let constraints = RTCMediaConstraints(mandatoryConstraints: [kRTCMediaConstraintsOfferToReceiveAudio: kRTCMediaConstraintsValueTrue], optionalConstraints: nil)
        
        peerConnection?.offer(for: constraints, completionHandler: { [weak self] (sdp, error) in
            guard let self = self, let sdp = sdp else {
                print("Failed to create offer: \(String(describing: error))")
                completion(nil)
                return
            }
            
            self.peerConnection?.setLocalDescription(sdp, completionHandler: { error in
                if let error = error {
                    print("Failed to set local description: \(error.localizedDescription)")
                    completion(nil)
                } else {
                    // print("Local description set successfully")
                    completion(sdp)
                }
            })
        })
    }
}

extension WebRTCManager: RTCPeerConnectionDelegate {
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) { }
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) { }
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) { }
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) { }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        delegate?.isICEGenerated(sdp: candidate.sdp)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) { }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        if let audioTrack = stream.audioTracks.first {
            // Forcing Audio Session to be
            AudioSessionManager.shared.forceSpeaker()
            self.remoteAudioTrack = audioTrack
            self.remoteAudioTrack?.isEnabled = true
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        if let audioTrack = stream.audioTracks.first {
            if audioTrack == self.remoteAudioTrack {
                self.remoteAudioTrack = nil
            }
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        
        if newState == .complete {
            // Created SDP to send
        }
    }
}
