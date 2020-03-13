Pod::Spec.new do |spec|

  spec.name         = "IdentifyKit"
  spec.version      = "1.21"
  spec.license      = "MIT"
  spec.summary      = "Swift package used to easily integrate classifier coreML models into your code."
  spec.homepage     = "https://github.com/appoly/IdentifyKit"
  spec.authors = "James Wolfe"
  spec.source = { :git => 'https://github.com/appoly/IdentifyKit.git', :tag => spec.version }

  spec.ios.deployment_target = "11.4"
  spec.framework = "UIKit"
  spec.framework = "ImageIO"
  spec.framework = "Vision"
  spec.framework = "CoreML"

  spec.swift_versions = ["5.0", "5.1"]
  
  spec.source_files = "Sources/*.swift"
  

end
