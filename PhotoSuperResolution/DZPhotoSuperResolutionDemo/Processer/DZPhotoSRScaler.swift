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

    func run(_ input: UIImage, factor: Float) async throws -> UIImage
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
    
    // This creates `CVPixelBuffer` from the provided `CVPixelBufferPool`.
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
    
    static func pixelBuffer(from image: UIImage,
                            with attributes: [String: any Sendable]?) throws -> CVPixelBuffer {
        
        guard let input = image.cgImage else {
            throw Fault.failedToRequestCGImage
        }
        let size = image.size
        var pixelBuffer:CVPixelBuffer? = nil
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         Int(size.width),
                                         Int(size.height),
                                         kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
                                         attributes as CFDictionary?,
                                         &pixelBuffer)

        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            throw Fault.failedToCreatePixelBuffer
        }
        
        let context = CIContext(options: [
            .cacheIntermediates: false,
            .outputColorSpace: CGColorSpaceCreateDeviceRGB()
        ])

        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }

        let ciImage = CIImage(cgImage: input)
        context.render(
            ciImage
                .transformed(by: CGAffineTransform(
                    scaleX: CGFloat(size.width)  / ciImage.extent.width,
                    y:      CGFloat(size.height) / ciImage.extent.height
                )),
            to: buffer,
            bounds: CGRect(origin: .zero, size: size),
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )
        
        return buffer
    }
    
    static func image(from buffer: CVPixelBuffer) throws -> UIImage {
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
