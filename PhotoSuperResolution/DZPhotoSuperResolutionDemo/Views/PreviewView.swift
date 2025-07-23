//
//  PreviewView.swift
//  DZPhotoSuperResolutionDemo
//
//  Created by Genning.Zhang on 2025/7/23.
//

import SwiftUI
import PhotosUI

struct DZPreviewView: View {
    
    @Environment(ContentViewData.self) private var datas
    @State private var selectedPhoto: PhotosPickerItem?
    
    var body: some View {
        
        let inputImage = datas.inputImage
        VStack {
            //input
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                DZImagePreviewView(image: inputImage,
                                   title: "点击选择图片",
                                   placeholder: "photo.badge.plus")
            }
            .onChange(of: selectedPhoto) {
                loadSelectedPhoto()
            }
            
            //output
            DZImagePreviewView(image: datas.outputImage,
                               title: "处理后的图片",
                               placeholder: "photo")
        }
    }
    
    private func loadSelectedPhoto() {
        guard let selectedPhoto = selectedPhoto else { return }
        Task { @MainActor in
            do {
                if let data = try await selectedPhoto.loadTransferable(type: Data.self) {
                    let uiImage = UIImage(data: data)
                    datas.inputImage = uiImage
                    datas.outputImage = nil
                    datas.factor = datas.supportFactors.last
                    datas.state = .idle
                }
            } catch {
                print("Failed to load image: \(error)")
                datas.inputImage = nil
            }
        }
    }
}
