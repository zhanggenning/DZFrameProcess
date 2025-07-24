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
        case upsupportFactor
        case unsupportEffect
    }
    
    static func createPhotoSRScaler(effect: SRScalerType,
                                    inputImage: UIImage?,
                                    factor: Float?) throws -> DZPhotoSRScaler {
        guard let input = inputImage else {
            throw Fault.inputIsNil
        }
        guard let factor = factor else {
            throw Fault.upsupportFactor
        }
        switch effect {
        case .lowlatency:
            return try DZLowLatencySRScaler(input: input, factor: factor)
        case .normal:
            return try DZNormalSRScaler(inputImage: input, factor: Int(factor))
        }
    }
}

extension DZPhotoProcesser {
    
    //是否支持
    static func isSupport(for effect: SRScalerType) -> Bool {
        switch effect {
        case .lowlatency:
            return VTLowLatencySuperResolutionScalerConfiguration.isSupported
        case .normal:
            return VTSuperResolutionScalerConfiguration.isSupported
        }
    }
    
    //支持的缩放倍数
    static func supportFactors(for effect: SRScalerType,
                               size: CGSize?) -> [Float] {
        switch effect {
        case .lowlatency:
            guard let size = size else { return [] }
            let w = Int(size.width), h = Int(size.height)
            return VTLowLatencySuperResolutionScalerConfiguration.supportedScaleFactors(frameWidth: w,
                                                                                        frameHeight: h)
        case .normal:
            return VTSuperResolutionScalerConfiguration.supportedScaleFactors.map { Float($0) }
        }
    }
    
    //最大尺寸
    static func maxSize(for effect: SRScalerType) -> CMVideoDimensions?{
        switch effect {
        case .lowlatency:
            return  VTLowLatencySuperResolutionScalerConfiguration.maximumDimensions
        case .normal:
            return VTSuperResolutionScalerConfiguration.maximumDimensions
        }
    }
    
    //最小尺寸
    static func minSize(for effect: SRScalerType) -> CMVideoDimensions? {
        switch effect {
        case .lowlatency:
            return VTLowLatencySuperResolutionScalerConfiguration.minimumDimensions
        case .normal:
            return VTSuperResolutionScalerConfiguration.minimumDimensions
        }
    }
    
    //是否需要模型
    static func isNeedModel(for effect: SRScalerType) -> Bool { effect == .normal }
}


enum SRScalerType: String, CaseIterable {
    case lowlatency = "Lowlatency"
    case normal = "Normal"
}
