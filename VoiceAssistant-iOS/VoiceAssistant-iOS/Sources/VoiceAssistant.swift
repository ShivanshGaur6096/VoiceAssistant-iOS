//
//  VoiceAssistant.swift
//  VoiceAssistant-iOS
//
//  Created by Shivansh Gaur on 24/02/25.
//

import Foundation
import UIKit

public protocol VoiceAssistantDelegate: AnyObject {
    func navigateToPage(_ page: String)
}

@objc
public class VoiceAssistant: NSObject {
    
    // Static reference to the floating button
    private static var floatingButton: UIButton?
    private static var floatingContainer: UIView?
    public static weak var delegate: VoiceAssistantDelegate?
    
    // Objective-C compatible static method to add a floating button
    @objc
    public static func addButton(
        to viewController: UIViewController,
        with config: VoiceAssistantConfig,
        details: AssistantModel
    ) {
        
        guard !config.tenantId.isEmpty else {
            debugPrint("Please provide Tenant-ID before initialising")
            return
        }
        
        ///  Generate New User Id everytime
        UserDefaults.standard.set(UUID().uuidString, forKey: "keyUserID")
        UserDefaults.standard.set(details.serverURL, forKey: "keyWebRTCServerURL")
        UserDefaults.standard.set(details.login, forKey: "keyLoginID")
        UserDefaults.standard.set(details.pass, forKey: "keyLoginPass")
        UserDefaults.standard.set(details.destination_number, forKey: "keyDestinationNumber")
        UserDefaults.standard.set(details.userVariablesAuthKey, forKey: "keyUserVariablesAuthKey")
        
        // Perform setup asynchronously for better performance
        DispatchQueue.global(qos: .userInitiated).async {
            configureButton(in: viewController, with: config)
        }
    }
    
    private static func configureButton(in viewController: UIViewController, with config: VoiceAssistantConfig) {
        
        // Ensure this method runs on the main thread
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                configureButton(in: viewController, with: config)
            }
            return
        }
        
        /// Remove any existing button first
        removeButton()
        
        /// Then Create a New button
        /// Based on `interactionMethod` add button to hosting app
        let buttonFrames = CGRect(x: viewController.view.frame.width - 80,
                                  y: viewController.view.frame.height - 80,
                                  width: 60, height: 60)

        let draggableContainer = DraggableContainerView(button: VoiceAssistantButtonFactory.createButton(with: config, frame: buttonFrames),
                                                        gifName: "loader_gif_4",
                                                        text: "Hi! I am Vini.\nClick here for any assistance",
                                                        viewController: viewController)
        
        viewController.view.addSubview(draggableContainer)
        floatingContainer = draggableContainer
    }
    
    public static func sendPageToNavigate(_ page: String) {
        delegate?.navigateToPage(page)
    }
    
    @objc
    public static func removeButton() {
        // Remove the button from its superview and release the reference
        if let floatingButtonView = floatingButton {
            floatingButtonView.removeFromSuperview()
            floatingButton = nil
        } else if let floatingContainerView = floatingContainer {
            floatingContainerView.removeFromSuperview()
            floatingContainer = nil
        }
    }
    
    @objc
    public static func ackEvent(name: String) {
        Signaling().sendRechargeSuccess(for: name)
    }
}
