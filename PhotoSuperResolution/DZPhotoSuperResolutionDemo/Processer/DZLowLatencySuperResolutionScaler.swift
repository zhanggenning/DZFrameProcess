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
    
    private var factor: Float = 1.0
    private var inputSize: CGSize = .zero
    
    nonisolated(unsafe) var frameProcessor: VTFrameProcessor? = VTFrameProcessor()
    private var configuration: VTLowLatencySuperResolutionScalerConfiguration? = nil
    private var pixelBufferPool: CVPixelBufferPool? = nil
    private var sourcePixelBufferAttributes: [String: any Sendable]? = nil
    
    func run(_ input: UIImage, factor: Float) async throws -> UIImage {

        //setup configuration
        try setup(input.size, factor: factor)
        
        //enhance
        let ret = try await enhance(input)
        
        return ret
    }
    
    private func check(width: Int, height: Int, factor: Float) throws {
        
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
    
    private func setup(_ inputSize: CGSize, factor: Float) throws {
        var isSetupConfiguration: Bool = (configuration == nil)
        if !isSetupConfiguration {
            isSetupConfiguration = !inputSize.equalTo(self.inputSize) || factor != self.factor
        }
        guard isSetupConfiguration else { return }
        let width = Int(inputSize.width)
        let height = Int(inputSize.height)
        try check(width: width, height: height, factor: factor)
        let configuration = VTLowLatencySuperResolutionScalerConfiguration(frameWidth: width,
                                                                           frameHeight: height,
                                                                           scaleFactor: factor)
        let destinationPixelBufferAttributes = configuration.destinationPixelBufferAttributes
        let pixelBufferPool = try Self.createPixelBufferPool(for: destinationPixelBufferAttributes)
        
        self.configuration = configuration
        self.pixelBufferPool = pixelBufferPool
        self.sourcePixelBufferAttributes = configuration.sourcePixelBufferAttributes
        self.inputSize = inputSize
        self.factor = factor
    }
    
    private func enhance(_ input: UIImage) async throws -> UIImage {
    
        var frameProcessor = self.frameProcessor
        if frameProcessor == nil {
            frameProcessor = VTFrameProcessor()
            self.frameProcessor = frameProcessor
        }
        
        try frameProcessor!.startSession(configuration: configuration!)
        defer {
            frameProcessor!.endSession()
        }
        
        let inputBuffer = try Self.pixelBuffer(from: input, with: sourcePixelBufferAttributes)
        guard let sourceFrame = VTFrameProcessorFrame(buffer: inputBuffer,
                                                      presentationTimeStamp: .zero) else {
            throw Fault.missingImageBuffer
        }
        
        let outputBuffer = try Self.createPixelBuffer(from: pixelBufferPool!)
        guard let destinationFrame = VTFrameProcessorFrame(buffer: outputBuffer,
                                                           presentationTimeStamp: .zero) else {
            throw Fault.missingImageBuffer
        }
        
        let parameters = VTLowLatencySuperResolutionScalerParameters(sourceFrame: sourceFrame,
                                                                     destinationFrame: destinationFrame)
        try await frameProcessor!.process(parameters: parameters)
    
        let output = try Self.image(from: outputBuffer)
        
        self.frameProcessor = nil
        
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
}
