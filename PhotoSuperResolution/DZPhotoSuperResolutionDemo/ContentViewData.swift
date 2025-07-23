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

    var scalerType: SRScalerType = .lowlatency
        
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
}

extension ContentViewData {
    enum Fault: Error {
        case inputIsNil
        case unsupportEffect
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

extension ContentViewData {
    
    @MainActor
    func process() async throws {
        let start = Int(CACurrentMediaTime()*1000)
        let scaler = try createPhotoSRScaler(type: scalerType)
        self.outputImage = try await scaler.run()
        let end = Int(CACurrentMediaTime()*1000)
        self.duration = end-start
    }
    
    private func createPhotoSRScaler(type: SRScalerType) throws -> DZPhotoSRScaler {
        guard let input = inputImage, let factor = factor else {
            throw Fault.inputIsNil
        }
        switch type {
        case .lowlatency:
            return try DZLowLatencySRScaler(input: input, factor: factor)
        case .normal:
            throw Fault.unsupportEffect
        }
    }
}
