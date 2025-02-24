//
//  MessageDisplayModel.swift
//  VoiceAssistant-iOS
//
//  Created by Shivansh Gaur on 24/02/25.
//

import Foundation

enum MessageType: String {
    case login = "verto.login"
//    case clientReady = "verto.clientReady"
//    case answer = "verto.answer"
//    case display = "verto.display"
    case ping = "verto.ping"
    case bye = "verto.bye"
    case startAsr = "start_asr"
    case stopAsr = "stop_asr"
}

// MARK: - MessageDisplayModel
struct MessageDisplayModel: Codable {
    let method: String
    let params: MessageDisplayParams
}

// MARK: - MessageDisplayParams
struct MessageDisplayParams: Codable {
    let display_name: String
    
    // Computed property to decode the nested JSON string
    var displayName: DisplayNameModel? {
        guard let data = display_name.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(DisplayNameModel.self, from: data)
    }
    
    enum CodingKeys: String, CodingKey {
        case display_name
    }
}

// MARK: - DisplayNameModel
struct DisplayNameModel: Codable {
    let transcription: String?
    let pageToNavigate: String?
    let eventName: String?
}
