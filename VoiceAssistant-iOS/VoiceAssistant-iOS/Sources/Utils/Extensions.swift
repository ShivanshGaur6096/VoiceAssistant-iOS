//
//  UIColor+Extensions.swift
//  VoiceAssistant-iOS
//
//  Created by Shivansh Gaur on 24/02/25.
//

import UIKit

extension UIColor {
    
    /// Initialize UIColor with a hex string
    /// - Parameters:
    ///   - hex: A hex color code string (e.g., "#RRGGBB" or "RRGGBBAA")
    ///   - alpha: Optional alpha value to override the one in the hex string (default: nil)
    convenience init?(hex: String, alpha: CGFloat? = nil) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            print("Invalid hex string")
            return nil // Invalid hex String
        }
        
        let length = hexSanitized.count
        switch length {
        case 6: // RGB (e.g., FF0000)
            let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            let blue = CGFloat(rgb & 0x0000FF) / 255.0
            self.init(red: red, green: green, blue: blue, alpha: alpha ?? 1.0)
        case 8: // RGBA (e.g., FF0000FF)
            let red = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            let green = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            let blue = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            let a = CGFloat(rgb & 0x000000FF) / 255.0
            self.init(red: red, green: green, blue: blue, alpha: alpha ?? a)
        default:
            print("Invalid hex string length")
            return nil
        }
    }
}

// MARK: - UIImage Extension

extension UIImage {
    /// Method to help us to display gif or animated image using image url on an image view
    static func gif(url: URL) -> (images: [UIImage], duration: TimeInterval)? {
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let count = CGImageSourceGetCount(imageSource)
        var images = [UIImage]()
        var duration: TimeInterval = 0.0
        
        for i in 0..<count {
            guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, i, nil) else { continue }
            images.append(UIImage(cgImage: cgImage))
            duration += gifDuration(imageSource: imageSource, index: i)
        }
        
        return (images, duration)
    }
    
    private static func gifDuration(imageSource: CGImageSource, index: Int) -> TimeInterval {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, index, nil) as? [String: Any],
              let gifProperties = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any],
              let delay = gifProperties[kCGImagePropertyGIFDelayTime as String] as? NSNumber else {
            return 0.1
        }
        return delay.doubleValue
    }
}
