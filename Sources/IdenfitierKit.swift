//
//  IdenfitierKit.swift
//  
//
//  Created by James Wolfe on 12/03/2020.
//

import Foundation
import UIKit
import ImageIO
import Vision
import CoreML




public protocol IdenfitierKitDelegate {
    func didIdentifyObject(name: String)
    func failedToIdentifyObject()
    func identifying()
    func failedToInitialize(error: String)
}



public class IdenfitierKit {
        
    // MARK: - Variables
    
    private let delegate: ObjectClassifierDelegate!
    private let accuracy: Float!
    private let model: MLModel!
    private var identified = false
    private lazy var classificationRequest: VNCoreMLRequest? = {
        do {
            let model = try VNCoreMLModel(for: self.model)
            
            let request = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in
                self?.processClassifications(for: request, error: error)
            })
            request.imageCropAndScaleOption = .centerCrop
            return request
        } catch {
            delegate?.failedToInitialize(error: error.localizedDescription)
            identified = false
            return nil
        }
    }()
    
    
    
    
    // MARK: - Initializers
    
    public init(delegate: ObjectClassifierDelegate, accuracy: Float, model: MLModel) {
        self.delegate = delegate
        self.accuracy = accuracy
        self.model = model
    }
    
    
    
    
    //MARK: - Utilities
    
    public func identify(_ data: Data) {
        DispatchQueue(label: "Classification").async { [weak self] in
            guard let image = UIImage(data: data) else {
                DispatchQueue.main.async { [weak self] in
                    self?.delegate.failedToIdentifyObject()
                    identified = false
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
                identified = false
            }
        }
        
        guard let orientation = CGImagePropertyOrientation(rawValue: UInt32(image.imageOrientation.rawValue)) else {
            DispatchQueue.main.async { [weak self] in
                self?.delegate.failedToIdentifyObject()
                identified = false
            }
            return
        }
        guard let ciImage = CIImage(image: image) else {
            DispatchQueue.main.async { [weak self] in
                self?.delegate.failedToIdentifyObject()
                identified = false
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
                identified = false
            }
        }
    }


    private func processClassifications(for request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNClassificationObservation] else {
            DispatchQueue.main.async { [weak self] in
                self?.delegate.failedToIdentifyObject()
                identified = false
            }
            return
        }
    
        if(results.isEmpty) {
            DispatchQueue.main.async { [weak self] in
                self?.delegate.failedToIdentifyObject()
                identified = false
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
                    identified = false
                }
            }
        }
    }

}
