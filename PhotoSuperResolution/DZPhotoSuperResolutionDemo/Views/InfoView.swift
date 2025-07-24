//
//  InfoView.swift
//  DZPhotoSuperResolutionDemo
//
//  Created by Genning.Zhang on 2025/7/23.
//

import SwiftUI
import CoreMedia

struct DZInfoView: View {
    
    @Environment(ContentViewData.self) private var datas
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                if let inputImage = datas.inputImage {
                    Text("Input: \(Int(inputImage.size.width))x\(Int(inputImage.size.height))")
                }
                if let outputImage = datas.outputImage {
                    Text("Output: \(Int(outputImage.size.width))x\(Int(outputImage.size.height))")
                }
            }
            HStack {
                if let maxSize = datas.maxSize {
                    Text("Max: \(maxSize.width)x\(maxSize.height)")
                } else {
                    Text("Max: nil")
                }
                if let minSize = datas.minSize {
                    Text("Min: \(minSize.width) x \(minSize.height)")
                } else {
                    Text("Min: nil")
                }
            }
            HStack {
                if let duration = datas.processDuration {
                    Text("Process: \(duration)mm")
                }
                
                if let duration = datas.downloadDuration {
                    Text("Download: \(duration)mm")
                }
            }

        }.font(.system(size: 13.0))
    }
}
