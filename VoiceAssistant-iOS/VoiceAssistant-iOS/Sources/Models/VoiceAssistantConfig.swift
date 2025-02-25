import UIKit

@objc public class VoiceAssistantConfig: NSObject {
    
    // MARK: Client Setup
    /// Provided Identification ID to client
    public let tenantId: String
    /// Prefered language code to communicate with Assistant
    public let languageCode: String
    
    // MARK: Floating Button UI Setup
    /// If you wish to display an image on floating button
    public let buttonImage: String?
    /// **else** provide a `Text` and `Background Colour` to make button noticeable
    /// In case, found `nil` then default values will be assigned `Call` `Black` in colour with `Grey` background colour
    public let setTitle: String?
    public let setTitleColor: UIColor?
    public let backgroundColor: UIColor?
    
    /// Provide corner radius to floating button, to make it round
    public let cornerRadius: CGFloat?
    
    /// Config floating button with NO button Image
    @objc public init(tenantId: String,
                      languageCode: String,
                      buttonTitle: String,
                      buttonTitleColor: UIColor,
                      buttonBgColor: UIColor,
                      cornerRadius: CGFloat) {
        self.tenantId = tenantId
        self.languageCode = languageCode
        self.setTitle = buttonTitle
        self.setTitleColor = buttonTitleColor
        self.backgroundColor = buttonBgColor
        self.cornerRadius = cornerRadius
        self.buttonImage = nil
    }
    
    /// Config floating button with button Image
    @objc public init(tenantId: String,
                      languageCode: String,
                      buttonImage: String,
                      cornerRadius: CGFloat) {
        self.tenantId = tenantId
        self.languageCode = languageCode
        self.buttonImage = buttonImage
        self.cornerRadius = cornerRadius
        self.setTitle = nil
        self.setTitleColor = nil
        self.backgroundColor = nil
    }
}

@objc public class AssistantModel: NSObject {
    public let serverURL: String
    public let login: String
    public let pass: String
    public let destination_number: String
    public let userVariablesAuthKey: String
    
    @objc public init(
        serverURL: String,
        login: String,
        pass: String,
        destination_number: String,
        userVariablesAuthKey: String
    ) {
        self.serverURL = serverURL
        self.login = login
        self.pass = pass
        self.destination_number = destination_number
        self.userVariablesAuthKey = userVariablesAuthKey
    }
    
}
