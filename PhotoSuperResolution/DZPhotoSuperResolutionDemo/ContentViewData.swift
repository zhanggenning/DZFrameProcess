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
    
    enum SRScalerType {
        case lowlatency
        case normal
    }
    
    var state: State = .idle
    
    var inputImage: UIImage? = nil
    var outputImage: UIImage? = nil
    var factor: Float? = nil
    
    var duration: Int? = nil

    var scalerType: SRScalerType = .lowlatency {
        didSet {
            guard oldValue != scalerType else { return }
            switch scalerType {
            case .lowlatency: scaler = DZLowLatencySRScaler()
            case .normal:     scaler = DZLowLatencySRScaler()
            }
        }
    }
    private var scaler: DZPhotoSRScaler = DZLowLatencySRScaler()
        
    var shareItems: [UIImage] {
        outputImage != nil ? [outputImage!] : []
    }
    
    func reset() {
        state = .idle
        inputImage = nil
        outputImage = nil
        factor = nil
        duration = nil
    }
    
    func process() async throws {
        guard let inputImage = inputImage else { return }
        guard let factor = factor else { return }
        let start = Int(CACurrentMediaTime()*1000)
        outputImage = try await scaler.run(inputImage, factor: factor)
        let end = Int(CACurrentMediaTime()*1000)
        duration = end-start
    }
}

extension ContentViewData {
    //是否支持
    var isSupport: Bool {
        switch scalerType {
        case .lowlatency: return DZLowLatencySRScaler.isSupported
        case .normal: return false
        }
    }
    
    //支持的缩放倍数
    var supportFactors: [Float] {
        guard let size = inputImage?.size else { return [] }
        switch scalerType {
        case .lowlatency:
            return DZLowLatencySRScaler.supportedScaleFactors(size: size)
        case .normal:
            return []
        }
    }
    
    //最大尺寸
    var maxSize: CMVideoDimensions? {
        switch scalerType {
        case .lowlatency: return DZLowLatencySRScaler.maximumDimensions
        case .normal: return nil
        }
    }
    
    //最小尺寸
    var minSize: CMVideoDimensions? {
        switch scalerType {
        case .lowlatency: return DZLowLatencySRScaler.minimumDimensions
        case .normal: return nil
        }
    }
}
