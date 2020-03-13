//
//  ObjectClassifier.swift
//  
//
//  Created by James Wolfe on 12/03/2020.
//

import Foundation
import UIKit
import ImageIO
import Vision
import CoreML




protocol ObjectClassifierDelegate {
    func didIdentifyObject(name: String)
    func failedToIdentifyObject()
    func identifying()
    func failedToInitialize(error: String)
}



class ObjectClassifier {
        
    // MARK: - Variables
    
    var delegate: ObjectClassifierDelegate!
    var accuracy: Float!
    let model: MLModel!
    public var identified = false
    lazy var classificationRequest: VNCoreMLRequest? = {
        do {
            let model = try VNCoreMLModel(for: self.model)
            
            let request = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in
                self?.processClassifications(for: request, error: error)
            })
            request.imageCropAndScaleOption = .centerCrop
            return request
        } catch {
            delegate?.failedToInitialize(error: error.localizedDescription)
            return nil
        }
    }()
    
    
    
    
    // MARK: - Initializers
    
    init(delegate: ObjectClassifierDelegate, accuracy: Float, model: MLModel) {
        self.delegate = delegate
        self.accuracy = accuracy
        self.model = model
    }
    
    
    
    
    //MARK: - Utilities
    
    public func restart() {
        identified = false
    }
    
    
    public func identify(_ data: Data) {
        DispatchQueue(label: "Classification").async { [weak self] in
            guard let image = UIImage(data: data) else {
                DispatchQueue.main.async { [weak self] in
                    self?.delegate.failedToIdentifyObject()
                }
                return
            }
            
            self?.updateClassifications(for: image)
        }
    }
    
    
    private func updateClassifications(for image: UIImage) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if(!self.identified) {
                self.delegate.identifying()
            }
        }
        
        guard let orientation = CGImagePropertyOrientation(rawValue: UInt32(image.imageOrientation.rawValue)) else {
            DispatchQueue.main.async { [weak self] in
                self?.delegate.failedToIdentifyObject()
            }
            return
        }
        guard let ciImage = CIImage(image: image) else {
            DispatchQueue.main.async { [weak self] in
                self?.delegate.failedToIdentifyObject()
            }
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
            do {
                if let request = self?.classificationRequest {
                    try handler.perform([request])
                }
            } catch {
                self?.delegate.failedToIdentifyObject()
            }
        }
    }


    private func processClassifications(for request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNClassificationObservation] else {
            DispatchQueue.main.async { [weak self] in
                self?.delegate.failedToIdentifyObject()
            }
            return
        }
    
        if(results.isEmpty) {
            DispatchQueue.main.async { [weak self] in
                self?.delegate.failedToIdentifyObject()
            }
        } else {
            let topClassifications = results.filter { $0.confidence > accuracy }.sorted(by: { $0.confidence > $1.confidence })
            
            if(topClassifications.count > 0) {
                DispatchQueue.main.async { [weak self] in
                    let identifier = topClassifications.first?.identifier
                    let name = identifier?.components(separatedBy: ",").first ?? ""
                    self?.identified = true
                    self?.delegate?.didIdentifyObject(name: name.capitalized)
                }
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.delegate.failedToIdentifyObject()
                }
            }
        }
    }

}
