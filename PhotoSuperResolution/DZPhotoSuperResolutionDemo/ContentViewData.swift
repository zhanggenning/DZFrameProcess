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
        case downing(progress: Float)
        case processing
        case completed
        
        var message: String? {
            switch self {
            case .idle, .completed:
                return nil
            case .downing(let progress):
                let percent = Int(progress * 100)
                return "下载模型中... \(percent)%"
            case .processing:
                return "处理中..."
            }
        }
        
        var isLoading: Bool {
            switch self {
            case .downing, .processing:
                return true
            default:
                return false
            }
        }
    }
    
    var state: State = .idle
    
    var inputImage: UIImage? = nil {
        didSet {
            state = .idle
            outputImage = nil
            factor = supportFactors.last
            processDuration = nil
            downloadDuration = nil
        }
    }
    var outputImage: UIImage? = nil
    var factor: Float? = nil
    
    var downloadDuration: Int? = nil
    var processDuration: Int? = nil

    var scalerType: SRScalerType = .normal {
        didSet {
            guard oldValue != scalerType else { return }
            factor = supportFactors.first
            processDuration = nil
            downloadDuration = nil
        }
    }
    
    func reset() {
        state = .idle
        inputImage = nil
        outputImage = nil
        factor = supportFactors.first
        downloadDuration = nil
        processDuration = nil
    }
}

extension ContentViewData {
    
    var isSupport: Bool { DZPhotoProcesser.isSupport(for: scalerType) }
    
    var maxSize: CMVideoDimensions? { DZPhotoProcesser.maxSize(for: scalerType) }
    
    var minSize: CMVideoDimensions? { DZPhotoProcesser.minSize(for: scalerType) }
    
    var supportFactors: [Float] { DZPhotoProcesser.supportFactors(for: scalerType, size: inputImage?.size) }
    
    var isNeedModel: Bool { DZPhotoProcesser.isNeedModel(for: scalerType) }
    
    func createSRScaler() throws -> DZPhotoSRScaler {
        try DZPhotoProcesser.createPhotoSRScaler(effect: scalerType, inputImage: inputImage, factor: factor)
    }
}
