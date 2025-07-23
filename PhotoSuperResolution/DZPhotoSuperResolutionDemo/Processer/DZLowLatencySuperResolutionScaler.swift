//
//  DZLowLatencySuperResolutionScaler.swift
//  DZPhotoSuperResolutionDemo
//
//  Created by Genning.Zhang on 2025/7/22.
//

import Foundation
import UIKit
@preconcurrency import VideoToolbox

actor DZLowLatencySRScaler: DZPhotoSRScaler {
    
    private let inputImage: UIImage
    private let factor: Float
    private var inputSize: CGSize { inputImage.size }
    
    nonisolated(unsafe) let frameProcessor: VTFrameProcessor = VTFrameProcessor()
    
    private var configuration: VTLowLatencySuperResolutionScalerConfiguration
    private var inputPixelBufferPool: CVPixelBufferPool
    private var outputPixelBufferPool: CVPixelBufferPool
    
    init(input: UIImage, factor: Float) throws {
        self.inputImage = input
        self.factor = factor
        
        let width = Int(inputImage.size.width)
        let height = Int(inputImage.size.height)
        try Self.check(width: width, height: height, factor: factor)
        configuration = VTLowLatencySuperResolutionScalerConfiguration(frameWidth: width,
                                                                       frameHeight: height,
                                                                       scaleFactor: factor)
        let outPixelBufferAttributes = configuration.destinationPixelBufferAttributes
        outputPixelBufferPool = try Self.createPixelBufferPool(for: outPixelBufferAttributes)
        
        let inPixelBufferAttributes = configuration.sourcePixelBufferAttributes
        inputPixelBufferPool = try Self.createPixelBufferPool(for: inPixelBufferAttributes)
    }

    func run() async throws -> UIImage {
    
        try frameProcessor.startSession(configuration: configuration)
        defer {
            frameProcessor.endSession()
        }
        
        let inputBuffer = try await Self.createPixelBuffer(from: inputImage, in: inputPixelBufferPool)
        guard let sourceFrame = VTFrameProcessorFrame(buffer: inputBuffer,
                                                      presentationTimeStamp: .zero) else {
            throw Fault.missingImageBuffer
        }
        
        let outputBuffer = try Self.createPixelBuffer(from: outputPixelBufferPool)
        guard let destinationFrame = VTFrameProcessorFrame(buffer: outputBuffer,
                                                           presentationTimeStamp: .zero) else {
            throw Fault.missingImageBuffer
        }
        
        let parameters = VTLowLatencySuperResolutionScalerParameters(sourceFrame: sourceFrame,
                                                                     destinationFrame: destinationFrame)
        try await frameProcessor.process(parameters: parameters)
    
        let output = try Self.createImage(from: outputBuffer)
        
        return output
    }
}

extension DZLowLatencySRScaler {
    
    static var isSupported: Bool {
        VTLowLatencySuperResolutionScalerConfiguration.isSupported
    }
    
    static var maximumDimensions: CMVideoDimensions? {
        VTLowLatencySuperResolutionScalerConfiguration.maximumDimensions
    }
    
    static var minimumDimensions: CMVideoDimensions? {
        VTLowLatencySuperResolutionScalerConfiguration.minimumDimensions
    }
    
    static func supportedScaleFactors(size: CGSize) -> [Float] {
        VTLowLatencySuperResolutionScalerConfiguration.supportedScaleFactors(frameWidth: Int(size.width), frameHeight: Int(size.height))
    }
    
    static func check(width: Int, height: Int, factor: Float) throws {
        
        guard VTLowLatencySuperResolutionScalerConfiguration.isSupported else {
            throw Fault.unsupportedProcessor
        }

        guard let maximumDimensions = VTLowLatencySuperResolutionScalerConfiguration.maximumDimensions,
            width <= maximumDimensions.width,
            height <= maximumDimensions.height
        else {
            throw Fault.dimensionsTooLarge
        }

        guard let minimumDimensions = VTLowLatencySuperResolutionScalerConfiguration.minimumDimensions,
            width >= minimumDimensions.width,
            height >= minimumDimensions.height
        else {
            throw Fault.dimensionsTooSmall
        }
        
        // Get supported scale factors.
        let supportedScaleFactors = VTLowLatencySuperResolutionScalerConfiguration.supportedScaleFactors(frameWidth: width,
                                                                                                         frameHeight: height)
        guard supportedScaleFactors
            .contains(where: { abs($0 - factor) < 0.001 }) else {
            throw Fault.unsupportScaleFactors
        }
    }
}
