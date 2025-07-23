//
//  ContentView.swift
//  DZPhotoSuperResolutionDemo
//
//  Created by Genning.Zhang on 2025/7/17.
//

import SwiftUI
import PhotosUI

struct ContentView: View {
        
    @Environment(ContentViewData.self) private var datas
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8.0) {
            DZPreviewView()
            DZInfoView()
            Spacer()
            ProcessToolView()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .HUD(isShown: .constant(datas.state == .processing), message: "处理中...")
    }
}

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

struct DZInfoView: View {
    
    @Environment(ContentViewData.self) private var datas
    
    var body: some View {
        let inputImage = datas.inputImage
        let outputImage = datas.outputImage
        VStack(alignment: .leading) {
            HStack {
                if let inputImage = inputImage {
                    Text("Input: \(Int(inputImage.size.width))x\(Int(inputImage.size.height))")
                }
                if let outputImage = outputImage {
                    Text("Output: \(Int(outputImage.size.width))x\(Int(outputImage.size.height))")
                }
            }
            HStack {
                if let maxSize = datas.maxSize {
                    Text("Max: \(maxSize.width)x\(maxSize.height)")
                }
                if let minSize = datas.minSize {
                    Text("Min: \(minSize.width) x \(minSize.height)")
                }
            }
            if let duration = datas.duration {
                Text("Duration: \(duration)mm")
            }
        }.font(.system(size: 13.0))
    }
}

struct ProcessToolView: View {
    
    @Environment(ContentViewData.self) private var datas
    
    @State private var infoMsg: String? = nil
    @State private var isShowShare: Bool = false

    var body: some View {
        HStack() {
        
            ToolButton("play") { process() }
                .disabled(!datas.isSupport || datas.inputImage == nil)
            
            ToolButton("arrow.trianglehead.counterclockwise") { datas.reset() }
            
            ToolButton("tray.and.arrow.down") { save() }
                .disabled(datas.outputImage == nil)
            
            ToolButton("square.and.arrow.up") { isShowShare = true }
                .share(isShown: $isShowShare, items: datas.shareItems)
                .disabled(datas.outputImage == nil)
            
            if !datas.supportFactors.isEmpty {
                FactorMenu("factor")
            }
        }
        .padding()
        .frame(minHeight: 44.0)
        .ErrorAlert(message: $infoMsg)
    }
    
    @ViewBuilder
    private func ToolButton(_ icon: String, action:(()->Void)? = nil) -> some View {
        Button {
            action?()
        } label: {
            Image(systemName: icon)
        }.frame(minWidth: 44.0)
    }
    
    @ViewBuilder
    private func FactorMenu(_ title: String) -> some View {
        Picker(title, selection: Binding(
            get: { datas.factor ?? 0 },
            set: { datas.factor = $0})
        ){
            ForEach(datas.supportFactors, id: \.self) { factor in
                Text(String(format: "x%.1f", factor))
                    .tag(factor)
            }
        }
        .pickerStyle(.menu)
        .frame(minWidth: 80.0)
        .disabled(datas.factor == nil)
    }
    
    private func save() {
        guard let image = datas.outputImage else { return }
        Task { @MainActor in
            do {
                try await DZPhotoHelper.save(image: image)
                infoMsg = "保存成功"
            } catch {
                infoMsg = "保存失败. error: \(error)"
            }
        }
    }
    
    private func process() {
        print("开始处理....")
        datas.state = .processing
        
        //开始处理
        Task { @MainActor in
            defer { datas.state = .completed }
            do {
                try await datas.process()
            }
            catch { infoMsg = String(describing: error) }
        }
    }
}

#Preview {
    ContentView().environment(ContentViewData())
}
