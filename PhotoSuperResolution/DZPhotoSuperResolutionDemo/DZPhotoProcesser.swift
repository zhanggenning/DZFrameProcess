//
//  DZPhotoProcesser.swift
//  DZPhotoSuperResolutionDemo
//
//  Created by Genning.Zhang on 2025/7/23.
//

import SwiftUI
import CoreMedia
@preconcurrency import VideoToolbox

@MainActor
final class DZPhotoProcesser {
    
    enum Fault: Error {
        case inputIsNil
        case unsupportEffect
    }
    
    static func createPhotoSRScaler(effect: SRScalerType,
                                    inputImage: UIImage?,
                                    factor: Float?) throws -> DZPhotoSRScaler {
        guard let input = inputImage, let factor = factor else {
            throw Fault.inputIsNil
        }
        switch effect {
        case .lowlatency:
            return try DZLowLatencySRScaler(input: input, factor: factor)
        case .normal:
            throw Fault.unsupportEffect
        }
    }

}

extension DZPhotoProcesser {
    
    //是否支持
    static func isSupport(for effect: SRScalerType) -> Bool {
        switch effect {
        case .lowlatency:
            return VTLowLatencySuperResolutionScalerConfiguration.isSupported
        case .normal: return false
        }
    }
    
    //支持的缩放倍数
    static func supportFactors(for effect: SRScalerType,
                               size: CGSize) -> [Float] {
        let w = Int(size.width), h = Int(size.height)
        switch effect {
        case .lowlatency:
            return VTLowLatencySuperResolutionScalerConfiguration.supportedScaleFactors(frameWidth: w,
                                                                                        frameHeight: h)
        case .normal:
            return []
        }
    }
    
    //最大尺寸
    static func maxSize(for effect: SRScalerType) -> CMVideoDimensions?{
        switch effect {
        case .lowlatency:
            return  VTLowLatencySuperResolutionScalerConfiguration.maximumDimensions
        case .normal:
            return nil
        }
    }
    
    //最小尺寸
    static func minSize(for effect: SRScalerType) -> CMVideoDimensions? {
        switch effect {
        case .lowlatency:
            return VTLowLatencySuperResolutionScalerConfiguration.minimumDimensions
        case .normal:
            return nil
        }
    }
}


enum SRScalerType {
    case lowlatency
    case normal
}
