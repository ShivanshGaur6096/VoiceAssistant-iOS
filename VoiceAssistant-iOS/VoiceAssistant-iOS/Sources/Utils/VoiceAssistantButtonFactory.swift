//
//  VoiceAssistantButtonFactory.swift
//  VoiceAssistant-iOS
//
//  Created by Shivansh Gaur on 24/02/25.
//

import UIKit

class VoiceAssistantButtonFactory {
    
    static func createButton(with config: VoiceAssistantConfig, frame: CGRect) -> UIButton {
        
        let button = UIButton(type: .custom)
        button.frame = frame
        
        /// Either host can apply image or a text and image will be on priority
        if let buttonImage = config.buttonImage {
            button.setImage(UIImage(named: buttonImage), for: .normal)
            button.imageView?.contentMode = .scaleAspectFill
            button.backgroundColor = .clear
            button.imageView?.layer.cornerRadius = config.cornerRadius ?? 30.0 // Default corner radius
        } else {
            button.setTitle(config.setTitle ?? "Call", for: .normal)
            button.setTitleColor(config.setTitleColor ?? .white, for: .normal)
            button.backgroundColor = config.backgroundColor ?? .black
            button.layer.cornerRadius = config.cornerRadius ?? 30.0
        }
        
        return button
    }
}

extension UIButton {
    
    @objc func handleDrag(_ sender: UIPanGestureRecognizer) {
        
        guard let button = sender.view as? UIButton else {
            print("Drag event is not associated with a UIButton.")
            return
        }
        
        let margin: CGFloat = 16
        guard let parentView = self.superview else { return }
        
        let safeAreaInsets = parentView.safeAreaInsets
        
        // Get the change in position from the gesture recognizer
        let translation = sender.translation(in: parentView)
        
        // Update the button's center position based on the translation
        button.center = CGPoint(x: button.center.x + translation.x, y: button.center.y + translation.y)
        
        // Reset the translation so that the next callback is relative to the current position
        sender.setTranslation(.zero, in: parentView)
        
        if sender.state == .ended {
            let buttonWidth = button.frame.width
            let buttonHeight = button.frame.height
            let parentWidth = parentView.frame.width
            let parentHeight = parentView.frame.height
            
            // Snap to left or right edges
            var finalX: CGFloat = 0
            if button.center.x <= parentWidth / 2 {
                finalX = margin + buttonWidth / 2 // Snap to left
            } else {
                finalX = parentWidth - margin - buttonWidth / 2 // Snap to right
            }
            
            // Ensure the button stays within vertical bounds (respect safe area)
            var finalY = button.center.y
            finalY = max(buttonHeight / 2 + safeAreaInsets.top, min(finalY, parentHeight - buttonHeight / 2 - safeAreaInsets.bottom))
            
            // Animate snapping
            UIView.animate(withDuration: 0.2) {
                button.center = CGPoint(x: finalX, y: finalY)
            }
        }
    }
}
