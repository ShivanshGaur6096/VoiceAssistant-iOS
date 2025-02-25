//
//  DraggableContainerView.swift
//  VoiceAssistant-iOS
//
//  Created by Shivansh Gaur on 24/02/25.
//

import UIKit

class DraggableContainerView: UIView {
    
    private let button: UIButton
    private var viewController: UIViewController
    private let textPadding: CGFloat = 8
    private let margin: CGFloat = 16
    
    private let normalSize: CGFloat = 90
    private let enlargedSize: CGFloat = 110 // Adjusted size
    
    // Timer to hide initial message
    private var hideMessageTimer: Timer?
    
    private var isSocketConnected: Bool = false
    private var isCallActive: Bool = false
    private var isNewCall: Bool = true
    private var isCallOnHold: Bool = false
    private var signaling: Signaling?
    
    // Lazy views: Only created when accessed
    private lazy var gifView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()
    
    private lazy var textView: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()
    
    private lazy var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "#E15141")
        view.layer.cornerRadius = 5
        view.clipsToBounds = true
        view.isHidden = true
        return view
    }()
    
    init(button: UIButton, gifName: String? = nil, text: String? = nil, viewController: UIViewController) {
        self.button = button
        self.viewController = viewController
        super.init(frame: .zero)
        
        setupView()
        setupGestures()
        
        if let gifName = gifName {
            displayGIF(named: gifName)
        }
        
        if let text = text {
            textView.text = text
        }
        
        if isNewCall {
            signaling = Signaling()
            signaling?.delegate = self
            signaling?.connectSocket()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods
    private func setupView() {
        self.frame = CGRect(
            x: UIScreen.main.bounds.width - normalSize - margin,
            y: UIScreen.main.bounds.height - normalSize - margin,
            width: normalSize,
            height: normalSize
        )
        
        addSubview(button)
        button.center = CGPoint(x: bounds.midX, y: bounds.midY)
        button.alpha = 0.7
        button.addTarget(self, action: #selector(startCallTapped), for: .touchUpInside)
        
        addSubview(backgroundView)
        addSubview(textView)
    }
    
    private func setupGestures() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleDrag(_:)))
        self.addGestureRecognizer(panGesture)
        self.isUserInteractionEnabled = true
    }
    
    private func hideInitialMessage() {
        hideMessageTimer?.invalidate()
        textView.isHidden = true
        backgroundView.isHidden = true
    }
    
    // Update UI when call state changes
    private func updateCallUI(startingCall: Bool) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.3) {
                let size = startingCall ? self.enlargedSize : self.normalSize
                self.bounds.size = CGSize(width: size, height: size)
                self.button.center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
                self.gifView.frame = self.bounds
            }
        }
    }
    
    // Handle End Call Button Tap
    @objc private func endCallButtonTapped() {
        signaling?.endCall()
        isCallActive = false
        isNewCall = true
        isCallOnHold = false
        
        // Hide gifView for end call
        DispatchQueue.main.async {
            self.gifView.isHidden = true
            self.updateCallUI(startingCall: false) // Shrinks when call ends
        }
    }
    
    // Handle Hold Call Button Tap
    @objc private func holdCallButtonTapped() {
        signaling?.holdCall()
        isCallOnHold.toggle()
        updateCallUI(startingCall: !isCallOnHold) // Shrinks when on hold
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.gifView.isHidden = self.isCallOnHold
        }
    }
    
    private func noInternetPopup() {
//        guard let viewController else { return }
        DispatchQueue.main.async {
            AlertManager.showAlert(
                on: self.viewController,
                title: "No Internet Connection",
                message: "Please check your internet settings.",
                buttonTitles: ["Settings", "Cancel"],
                actions: [
                    {
                        // Open device settings
                        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                        UIApplication.shared.open(url)
                    },
                    {
                        // Cancel action
                        print("Internet Connection not found and cancel button tapped")
                    }
                ])
        }
    }
    
    @objc private func startCallTapped() {
        guard NetworkMonitor.shared.isConnectedToInternet() else {
            noInternetPopup()
            return
        }
        
        AudioSessionManager.shared.checkMicrophonePermission { isGranted in
            if isGranted {
                if !self.isSocketConnected {
                    // Try reconnecting the socket
                    self.signaling?.connectSocket()
                    
                    // Wait for connection and then start call
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        if self.isSocketConnected {
                            self.signaling?.startCall()
                        } else {
                            print("Socket reconnection failed.")
                        }
                    }
                    return
                }
                
                if !(self.isCallActive) {
                    self.isCallActive = true // Expands the view
                    self.updateCallUI(startingCall: true)
                    self.displayGIF(named: "loader_gif_4", shouldOverlay: true)
                    
                    // TODO: In case if call doesn't start, socket issue
                    /// Keep interaction disable for few second and after that if socket doesn't connect do the following:
                    /// stop ringer audio
                    /// stop trying connectiong socket
                    /// make button normal instead of transparent and remove gif
                    guard self.isNewCall else { return }
                    
                    self.signaling?.startCall() // FOR MWC to just start voice
                    self.isNewCall = false
                    self.isCallActive = true
                    self.isCallOnHold = false
                } else {
                    // MARK: Instead of disconnecting call just sent "Stop ASR" by hold call
//            endCallButtonTapped()
                    self.holdCallButtonTapped()
                }
            } else {
                DispatchQueue.main.async {
                    AudioSessionManager.shared.showMicrophonePermissionAlert(on: self.viewController)
                }
            }
        }
    }
    
    private func displayGIF(named gifName: String, shouldOverlay: Bool = false) {
        guard let gifUrl = Bundle(for: DraggableContainerView.self).url(forResource: gifName, withExtension: "gif"),
              let gifData = UIImage.gif(url: gifUrl) else { return }
        
        DispatchQueue.main.async {
            self.gifView.image = UIImage.animatedImage(with: gifData.images, duration: gifData.duration)
            self.gifView.isHidden = false
            self.addSubview(self.gifView)
            
            if shouldOverlay {
                self.bringSubviewToFront(self.gifView)
            } else {
                self.sendSubviewToBack(self.gifView)
            }
        }
    }
    
    private func updateTextViewPosition() {
        
        let maxWidth = UIScreen.main.bounds.width * 0.6
        let textSize = textView.sizeThatFits(CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude))
        textView.frame = CGRect(x: 0, y: 0, width: textSize.width, height: textSize.height)
        
        backgroundView.frame = CGRect(
            x: 0, y: 0,
            width: textView.frame.width + textPadding * 2,
            height: textView.frame.height + textPadding * 2
        )
        
        // Position text beside the button
        if center.x <= UIScreen.main.bounds.width / 2 {
            backgroundView.center = CGPoint(x: button.frame.maxX + backgroundView.frame.width / 2 + 10,
                                            y: button.center.y)
        } else {
            backgroundView.center = CGPoint(x: button.frame.minX - backgroundView.frame.width / 2 - 10,
                                            y: button.center.y)
        }
        textView.center = backgroundView.center
    }
    
    @objc private func handleDrag(_ sender: UIPanGestureRecognizer) {
        guard let parentView = superview else { return }
        
        let translation = sender.translation(in: parentView)
        self.center = CGPoint(x: self.center.x + translation.x, y: self.center.y + translation.y)
        sender.setTranslation(.zero, in: parentView)
        
        if sender.state == .ended {
            snapToEdges()
        }
        
        // Update text position
//        updateTextViewPosition()
    }
    
    private func snapToEdges() {
        guard let parentView = superview else { return }
        let safeAreaInsets = parentView.safeAreaInsets
        let parentWidth = parentView.frame.width
        let parentHeight = parentView.frame.height
        
        let finalX: CGFloat = (self.center.x <= parentWidth / 2) ? margin + self.frame.width / 2 : parentWidth - margin - self.frame.width / 2
        let finalY = max(self.frame.height / 2 + safeAreaInsets.top, min(self.center.y, parentHeight - self.frame.height / 2 - safeAreaInsets.bottom))
        
        UIView.animate(withDuration: 0.2) {
            self.center = CGPoint(x: finalX, y: finalY)
        }
    }
}

extension DraggableContainerView: SignalingDelegate {
    
    func socketConnectionStatus(connected: Bool) {
        DispatchQueue.main.async {
            self.isSocketConnected = connected
            
            if connected {
                self.button.alpha = 1.0
                self.backgroundView.isHidden = false
                self.textView.isHidden = false
                
                // Ensure text appears at correct position
                self.updateTextViewPosition()
                
                // Hide message after 3 seconds
                self.hideMessageTimer?.invalidate()
                self.hideMessageTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
                    self?.hideInitialMessage()
                }
            } else {
                self.gifView.isHidden = true
                self.button.alpha = 0.7
                self.backgroundView.isHidden = true
                self.textView.isHidden = true
            }
        }
    }
    
    func botSpeakingStatus(isSpeaking: Bool) {
        DispatchQueue.main.async {
            let gifName = isSpeaking ? "play_anim_1" : "loader_gif_4"
            self.displayGIF(named: gifName, shouldOverlay: false)
            
            // Expand view on first "isSpeaking = true"
            if isSpeaking && !self.isCallActive {
                self.isCallActive = true
                self.updateCallUI(startingCall: true)
            }
        }
    }
    
    func signalingDidReceiveMessage(message: String) {
        // If you want to display the message on view
    }
}
