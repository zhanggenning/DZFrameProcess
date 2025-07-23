//
//  DZPhotoProcesser.swift
//  DZPhotoSuperResolutionDemo
//
//  Created by Genning.Zhang on 2025/7/21.
//

import Foundation
import UIKit
@preconcurrency import VideoToolbox

protocol DZPhotoSRScaler: Actor {
    
    typealias Fault = DZPhotoProcessError

    func run() async throws -> UIImage
}

extension DZPhotoSRScaler {
    
    static func createPixelBufferPool(for pixelBufferAttributes: [String: Any],
                                      count: Int = 2) throws -> CVPixelBufferPool {

        let pixelBufferPoolAttributes = [kCVPixelBufferPoolMinimumBufferCountKey as String: count]

        var pixelBufferPool: CVPixelBufferPool?
        CVPixelBufferPoolCreate(kCFAllocatorDefault,
                                pixelBufferPoolAttributes as NSDictionary?,
                                pixelBufferAttributes as NSDictionary?,
                                &pixelBufferPool)

        guard let pixelBufferPool else { throw Fault.failedToCreatePixelBufferPool }

        return pixelBufferPool
    }
    
    static func createPixelBuffer(from pixelBufferPool: CVPixelBufferPool) throws -> CVPixelBuffer {

        var outputPixelBuffer: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault,
                                            pixelBufferPool,
                                            &outputPixelBuffer)
        guard let outputPixelBuffer else {
            throw Fault.failedToCreatePixelBuffer
        }

        return outputPixelBuffer
    }
    
    static func createPixelBuffer(from image: UIImage, in pool: CVPixelBufferPool) async throws -> CVPixelBuffer {
        guard let input = image.cgImage else {
            throw Fault.failedToRequestCGImage
        }
        let buffer = try Self.createPixelBuffer(from: pool)
        let ctx = DZPhotoProcessContext.shared
        await ctx.render(cgImage: input, to: buffer)
        return buffer
    }
    
    static func createImage(from buffer: CVPixelBuffer) throws -> UIImage {
        var cgImage: CGImage?
        let status = VTCreateCGImageFromCVPixelBuffer(buffer, options: nil, imageOut: &cgImage)
        guard status == kCVReturnSuccess, let cgImage = cgImage else {
            throw Fault.failedToCreateCGImage
        }
        let ret = UIImage(cgImage: cgImage)
        return ret
    }
}

enum DZPhotoProcessError: Error {
    case unsupportedProcessor
    case dimensionsTooLarge
    case dimensionsTooSmall
    case unsupportScaleFactors
    case failedToCreatePixelBufferPool
    case failedToCreatePixelBuffer
    case failedToRequestCGImage
    case failedToCreateCGContext
    case failedToCreateCGImage
    case missingImageBuffer
}

actor DZPhotoProcessContext {
    
    static let shared = DZPhotoProcessContext()
    
    private let colorSpace = CGColorSpaceCreateDeviceRGB()
    
    let ctx = CIContext(options: [
        .cacheIntermediates: false,
        .outputColorSpace: CGColorSpaceCreateDeviceRGB()
    ])
    
    public func render(cgImage: CGImage, to buffer: CVPixelBuffer) {
        let ciImage = CIImage(cgImage: cgImage)
        let width = cgImage.width
        let height = cgImage.height
        let size = CGSize(width: width, height: height)
        ctx.render(
            ciImage,
            to: buffer,
            bounds: CGRect(origin: .zero, size: size),
            colorSpace: colorSpace
        )
    }
}
