//
//  DZSuperResolutionScaler.swift
//  DZPhotoSuperResolutionDemo
//
//  Created by Genning.Zhang on 2025/7/23.
//

import Foundation
import UIKit
@preconcurrency import VideoToolbox

actor DZNormalSRScaler: DZPhotoSRScaler {
    
    private let inputImage: UIImage
    private let factor: Int
    
    private nonisolated(unsafe) let frameProcessor: VTFrameProcessor = VTFrameProcessor()
    
    private(set) var configuration: VTSuperResolutionScalerConfiguration
    private var inputPixelBufferPool: CVPixelBufferPool
    private var outputPixelBufferPool: CVPixelBufferPool
    
    var isNeedDownloadModel: Bool {
        configuration.configurationModelStatus == .downloadRequired
    }
    
    var downingProgress: Float { configuration.configurationModelPercentageAvailable }
    
    init(inputImage: UIImage, factor: Int) throws {
        
        self.inputImage = inputImage
        self.factor = factor
        
        let width = Int(inputImage.size.width)
        let height = Int(inputImage.size.height)
        let configuration = VTSuperResolutionScalerConfiguration(frameWidth: width,
                                                                 frameHeight: height,
                                                                 scaleFactor: factor,
                                                                 inputType: .image,
                                                                 usePrecomputedFlow: false,
                                                                 qualityPrioritization: .normal,
                                                                 revision: .revision1)
        guard let configuration = configuration else {
            throw Fault.failedToCreateSRSConfiguration
        }
        self.configuration = configuration

        let outPixelBufferAttributes = configuration.destinationPixelBufferAttributes
        outputPixelBufferPool = try Self.createPixelBufferPool(for: outPixelBufferAttributes)
        
        let inPixelBufferAttributes = configuration.sourcePixelBufferAttributes
        inputPixelBufferPool = try Self.createPixelBufferPool(for: inPixelBufferAttributes)
    }
    
    func run() async throws -> UIImage {
        try frameProcessor.startSession(configuration: configuration)
        defer {
            CVPixelBufferPoolFlush(inputPixelBufferPool, .excessBuffers)
            CVPixelBufferPoolFlush(outputPixelBufferPool, .excessBuffers)
            frameProcessor.endSession()
        }
        
        guard configuration.configurationModelStatus == .ready else {
            throw Fault.modelIsNotReady
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
        
        let parameters = VTSuperResolutionScalerParameters(sourceFrame: sourceFrame,
                                                           previousFrame: nil,
                                                           previousOutputFrame: nil,
                                                           opticalFlow: nil,
                                                           submissionMode: .random,
                                                           destinationFrame: destinationFrame)
        guard let parameters = parameters else {
            throw Fault.failedToCreateSRSParameters
        }
        
        try await frameProcessor.process(parameters: parameters)
        
        let outputImage = try Self.createImage(from: inputBuffer)
        
        return outputImage
    }
    
    func modelDownloader() -> (any DZModelDownloader)? { self }
}

extension DZNormalSRScaler: DZModelDownloader {
    
    nonisolated func download() -> AsyncThrowingStream<Float, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                let processTask = Task {
                    while !Task.isCancelled {
                        let progress = await configuration.configurationModelPercentageAvailable
                        continuation.yield(progress)
                        
                        guard progress < 1 else { break }
                        try await Task.sleep(nanoseconds: 200_000_000)
                    }
                }
                
                defer { processTask.cancel() }
                
                do {
                    try await configuration.downloadConfigurationModel()
                    continuation.yield(1.0)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
