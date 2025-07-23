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
            DZToolsView()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .HUD(isShown: .constant(datas.state == .processing), message: "处理中...")
    }
}

#Preview {
    ContentView().environment(ContentViewData())
}
