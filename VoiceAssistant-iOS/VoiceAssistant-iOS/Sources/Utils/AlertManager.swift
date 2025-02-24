//
//  AlertManager.swift
//  VoiceAssistant-iOS
//
//  Created by Shivansh Gaur on 24/02/25.
//

import UIKit

public class AlertManager {
    public static func showAlert(
        on viewController: UIViewController,
        title: String? = nil,
        message: String? = nil,
        buttonTitles: [String],
        actions: [(() -> Void)?]
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        for (index, buttonTitle) in buttonTitles.enumerated() {
            let action = UIAlertAction(title: buttonTitle, style: .default) { _ in
                actions[index]?()
            }
            alert.addAction(action)
        }
        
        viewController.present(alert, animated: true, completion: nil)
    }
}
