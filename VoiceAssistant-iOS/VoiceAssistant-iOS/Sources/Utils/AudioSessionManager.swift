//
//  AudioSessionManager.swift
//  VoiceAssistant-iOS
//
//  Created by Shivansh Gaur on 24/02/25.
//

import UIKit
import AVFoundation

class AudioSessionManager {
    static let shared = AudioSessionManager()
    
    private init() {}
    
    // Configure the session for playback
    func configureForPlayback() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to configure audio session for playback: \(error.localizedDescription)")
        }
    }
    
    // Configure the session for Audio Calls
    func configureForAudioCall() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to configure audio session for playback: \(error.localizedDescription)")
        }
    }
    
    /// Forces the audio output to the speaker
    func forceSpeaker() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.overrideOutputAudioPort(.speaker)
        } catch {
            print("Failed to override output audio port: \(error.localizedDescription)")
        }
    }
    
    func checkMicrophonePermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
            
        case .notDetermined:
            // Permission not yet requested, ask for permission
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                if granted {
                    print("Microphone access granted after request.")
                    completion(true)
                } else {
                    print("Microphone access denied after request.")
                    completion(false)
                }
            }
        case .restricted, .denied:
            // Permission denied or restricted, inform the user
            print("Microphone access denied or restricted.")
            completion(false)
        case .authorized:
            // Permission granted, continue with audio recording
            print("Microphone access granted.")
            completion(true)
        @unknown default:
            print("Unknown microphone authorization status.")
            completion(false)
        }
    }
    
    func showMicrophonePermissionAlert(on viewController: UIViewController) {
        let alert = UIAlertController(title: "Microphone Access Required", message: "Please enable microphone access in Settings to use this feature.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default, handler: { _ in
            if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(appSettings)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        viewController.present(alert, animated: true, completion: nil)
    }
    
}
