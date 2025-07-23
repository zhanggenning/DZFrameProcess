//
//  ContentViewData.swift
//  DZPhotoSuperResolutionDemo
//
//  Created by Genning.Zhang on 2025/7/22.
//

import Foundation
import SwiftUI
import CoreMedia

@MainActor
@Observable
final class ContentViewData {
    
    enum State {
        case idle
        case processing
        case completed
    }
    
    var state: State = .idle
    
    var inputImage: UIImage? = nil
    var outputImage: UIImage? = nil
    var factor: Float? = nil
    
    var duration: Int? = nil

    var scalerType: SRScalerType = .lowlatency
        
    func reset() {
        state = .idle
        inputImage = nil
        outputImage = nil
        factor = nil
        duration = nil
    }
}

extension ContentViewData {
    
    var isSupport: Bool { DZPhotoProcesser.isSupport(for: scalerType) }
    
    var maxSize: CMVideoDimensions? { DZPhotoProcesser.maxSize(for: scalerType) }
    
    var minSize: CMVideoDimensions? { DZPhotoProcesser.minSize(for: scalerType) }
    
    var supportFactors: [Float] {
        guard let inputImage = inputImage else { return [] }
        return DZPhotoProcesser.supportFactors(for: scalerType, size: inputImage.size)
    }
    
    func createSRScaler() throws -> DZPhotoSRScaler {
        try DZPhotoProcesser.createPhotoSRScaler(effect: scalerType, inputImage: inputImage, factor: factor)
    }
}
