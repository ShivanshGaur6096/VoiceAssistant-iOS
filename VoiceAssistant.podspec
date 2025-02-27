Pod::Spec.new do |spec|
  spec.name         = "VoiceAssistant"
  spec.version      = "0.0.6"
  spec.summary      = "A powerful voice assistant framework for iOS."
  spec.description  = <<-DESC
  VoiceAssistant-iOS is framework designed by BlackNGreen for MWC-2025 to provide advanced voice assistant functionalities, 
  including speech recognition and real-time communication and hand-free navigation.
                   DESC

  spec.homepage     = "https://github.com/ShivanshGaur6096/VoiceAssistant-iOS.git"
  # spec.screenshots  = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author             = { "Shivansh Gaur" => "shivansh.gaur@blackngreen.com" }
  spec.ios.deployment_target = "15.0"
  spec.swift_version = '5.0'

  spec.source       = { :git => "https://github.com/ShivanshGaur6096/VoiceAssistant-iOS.git", :tag => "#{spec.version}" }

  spec.source_files = "VoiceAssistant-iOS/VoiceAssistant-iOS/Sources/**/*.{h,m,swift}"

  # ――― Project Linking ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  spec.frameworks = "Foundation", "UIKit", "AVFoundation"

  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  # **Dependency on WebRTC-lib**
  spec.dependency "WebRTC-lib", "130.0.0" # Adjust the version as required

  # Enable ARC for all source files
  spec.requires_arc = true

end
