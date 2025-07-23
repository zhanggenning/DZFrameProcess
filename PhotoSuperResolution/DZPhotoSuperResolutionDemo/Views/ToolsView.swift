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
        HStack() {
        
            ToolButton("play") { process() }
                .disabled(!datas.isSupport || datas.inputImage == nil)
            
            ToolButton("arrow.trianglehead.counterclockwise") { datas.reset() }
            
            ToolButton("tray.and.arrow.down") { save() }
                .disabled(datas.outputImage == nil)
            
            let shareItems = (datas.outputImage != nil ? [datas.outputImage!] : [])
            ToolButton("square.and.arrow.up") { isShowShare = true }
                .share(isShown: $isShowShare, items: shareItems)
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
        datas.state = .processing
        Task {
            defer { datas.state = .completed }
            do {
                let start = Int(CACurrentMediaTime()*1000)
                datas.outputImage = try await datas.createSRScaler().run()
                let end = Int(CACurrentMediaTime()*1000)
                datas.duration = end-start
            }
            catch { infoMsg = String(describing: error) }
        }
    }
}
