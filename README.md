# IdentifierKit
Swift package used to easily integrate classifier coreML models into your code.
 
**Installing with cocoapods**
```
pod 'IdentifierKit'
```

**Quick start**

First start by creating a IdentifierKitDelegate, this will handle the result of any identification or failed identification.
```
extension ViewController: IdentifierKitDelegate {
    func failedToInitialize(error: String) {
        print("Failed to initialize identifier request: \(error)")
    }
    
    
    func didIdentifyObject(name: String) {
        print("Identified: \(name)")
    }
    
    func identifying() {
        print("Identifying")
    }
    
    
    func failedToIdentifyObject() {
        print("Identification Failed")
    }
    
}
```

Once you have your delegate setup, you can initialize your IdentifierKit object. The initializer takes 3 arguments:

- The delegate which we declare above.
- The desired accuracy, which is a float between 0 & 1, will be used to filter out any identifications that are less accurate than this value.
- The model, which can be any image classification model. We've used MobileNet in this example.

`let classifier = IdentifierKit(delegate: self, accuracy: Configuration.accuracy, model: MobileNet().model)`

Once this is done you can make a request:
```
func identify(image: UIImage) {
    func identify(image: UIImage) {
        let image = UIImage()
        guard let data = image.pngData() else { return }
        classifier.identify(data)
    }
}
```
