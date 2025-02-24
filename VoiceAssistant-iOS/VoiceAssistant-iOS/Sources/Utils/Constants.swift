//
//  Constants.swift
//  VoiceAssistant-iOS
//
//  Created by Shivansh Gaur on 24/02/25.
//

import Foundation

public struct Constants {
    static let uuid = UserDefaults.standard.string(forKey: "keyUserID")
    
    struct WebRTCCalls {
        static let serverURL: String = "wss://eva-demo-backend.bngrenew.com:443/webrtc" // "wss://mwc-demo.bngrenew.com/webrtc"
        
        static func createLoginMessage() -> [String: Any] {
            
            let userVariables: [String: String] = [
                "client":"vini",
                "interface":"app",
                "email_id":"vini@gmail.com",
            ]
            
            let loginParams: [String: Any] = [
                "login": "admin@",
                "passwd": "admin",
                "loginParams": userVariables,
                "userVariables": userVariables,
                "sessid": Constants.uuid!
            ]
            
            let loginMessage: [String: Any] = [
                "jsonrpc": "2.0",
                "method": "login",
                "params": loginParams
            ]
            
            return loginMessage
        }
        
        static func createOfferMessage(offer: String) -> [String: Any] {
            
            let dialogParams: [String: Any] = [
                "callID": Constants.uuid!,
                "caller_id_name": "MWC_iOS",
                "caller_id_number": "9876543210",
                "destination_number": "2025",
                "sessid": Constants.uuid!,
                "useMic": "any",
                "useSpeak": "any",
                "useStereo": false,
                "useStream": false,
                "useVideo": false,
                "userVariables": ["auth_key": "Ym5nOmV2YQ"]
            ]
            
            let inviteParams: [String: Any] = [
                "sdp": offer,
                "dialogParams": dialogParams
            ]
            
            let offerDict: [String: Any] = [
                "jsonrpc": "2.0",
                "method": "verto.invite",
                "params": inviteParams
            ]
            
            return offerDict
        }
        
        static func startASR(for event: MessageType) -> [String: Any] {
            // let eventBody = "{\"hasRecharged\":\"\(true)\"}"
            let eventBody = "{}"
            
            // Format the asrBody string
            let asrBody = "{\"eventBody\": \(eventBody),\"eventName\":\"\(event.rawValue)\",\"callId\":\"\(Constants.uuid!)\"}"
            
            // Prepare the params for the request
            let asrparams: [String: Any] = [
                "msg": [
                    "to": "eva",
                    "body": asrBody
                ]
            ]
            
            let startASROffer: [String: Any] = [
                "jsonrpc":"2.0",
                "method":"verto.info",
                "params" : asrparams
            ]
            
            return startASROffer
        }
        
        static func sendBye(for eventName: MessageType) -> [String: Any] {
            let byeBody: [String: Any] = [
                "sessid": Constants.uuid!,
                "callID": Constants.uuid!
            ]
            
            let byeParams: [String: Any] = [
                "msg": ["to": "eva", "body": byeBody]
            ]
            
            let bye: [String: Any] = [
                "jsonrpc": "2.0",
                "method": eventName.rawValue,
                "param": byeParams
            ]
            
            return bye
        }
        
        static func sendPingResponse() -> [String: Any] {
            let pingResponse: [String: Any] = [
                "id": Constants.uuid!,
                "jsonrpc": "2.0",
                "result": ["method": "verto.ping"]
            ]
            
            return pingResponse
        }
        
        // MARK: Recharge Success Event
        // TODO: Need to configure it for 
        static func sendRechargeSuccessEvent(with packID: String) -> [String: Any] {
            var packDetails: String = ""
            switch packID {
            case "1":
                packDetails = "\"price\":\"449\",\"packId\":\"1\""
            case "2":
                packDetails = "\"price\":\"249\",\"packId\":\"2\""
            case "3":
                packDetails = "\"price\":\"349\",\"packId\":\"3\""
            default:
                break
            }
            
            let rechargeMessage: [String: Any] = [
                "to": "eva",
                "eventBody": "{\(packDetails)}",
                "eventName": "recharge_success",
                "callId": "\(Constants.uuid!)"
            ]
            
            let rechargeSuccessEvent: [String: Any] = [
                "jsonrpc": "2.0",
                "method":"verto.info",
                "params": ["msg": rechargeMessage]
            ]
            
            return rechargeSuccessEvent
        }
        
        
    }
}
