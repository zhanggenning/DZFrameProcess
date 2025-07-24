//
//  ToolsView.swift
//  DZPhotoSuperResolutionDemo
//
//  Created by Genning.Zhang on 2025/7/23.
//

import SwiftUI

struct DZToolsView: View {
    
    @Environment(ContentViewData.self) private var datas
    
    @State private var infoMsg: String? = nil
    @State private var isShowShare: Bool = false

    var body: some View {
        
        VStack(alignment: .trailing) {
            
            HStack {
                
                Spacer()
                
                if !datas.supportFactors.isEmpty {
                    FactorMenu("factor")
                }
                
                ProcesserMenu("scaler")
            }
            
            HStack() {

                Spacer()
                
                ToolButton("play") { process() }
                    .disabled(!datas.isSupport || datas.inputImage == nil)
                
                ToolButton("arrow.trianglehead.counterclockwise") { datas.reset() }
                
                ToolButton("tray.and.arrow.down") { save() }
                    .disabled(datas.outputImage == nil)
                
                let shareItems = (datas.outputImage != nil ? [datas.outputImage!] : [])
                ToolButton("square.and.arrow.up") { isShowShare = true }
                    .share(isShown: $isShowShare, items: shareItems)
                    .disabled(datas.outputImage == nil)
            }
        }
        .frame(minHeight: 44.0*2)
        .padding()
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
        Picker(title, selection: Binding<Float?>(
            get: { datas.factor },
            set: { datas.factor = $0})
        ){
            ForEach(datas.supportFactors, id: \.self) { factor in
                Text(String(format: "x%.1f", factor))
                    .tag(Optional(factor))
            }
        }
        .pickerStyle(.menu)
        .frame(minWidth: 80.0)
        .disabled(datas.factor == nil)
    }
    
    @ViewBuilder
    private func ProcesserMenu(_ title: String) -> some View {
        Picker("Scaler Type", selection: Binding(
            get: { datas.scalerType },
            set: { datas.scalerType = $0 })) {
            ForEach(SRScalerType.allCases, id: \.self) { type in
                Text(type.rawValue.capitalized).tag(type)
            }
        }
        .pickerStyle(.menu)
        .frame(minWidth: 80.0)
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
        Task {
            defer { datas.state = .completed }
            do {
                let scaler = try datas.createSRScaler()
                let isUseModel = await scaler.isNeedDownloadModel
                if isUseModel {
                    let dStart = Int(CACurrentMediaTime()*1000)
                    let downloader = await scaler.modelDownloader()!
                    for try await p in downloader.download() {
                        datas.state = .downing(progress: p)
                    }
                    let dEnd = Int(CACurrentMediaTime()*1000)
                    datas.downloadDuration = dEnd-dStart
                    datas.state = .processing
                    let pStart = Int(CACurrentMediaTime()*1000)
                    datas.outputImage = try await scaler.run()
                    let pEnd = Int(CACurrentMediaTime()*1000)
                    datas.processDuration = pEnd-pStart
                } else {
                    datas.state = .processing
                    let start = Int(CACurrentMediaTime()*1000)
                    datas.outputImage = try await scaler.run()
                    let end = Int(CACurrentMediaTime()*1000)
                    datas.processDuration = end-start
                }
            }
            catch { infoMsg = String(describing: error) }
        }
    }
}
