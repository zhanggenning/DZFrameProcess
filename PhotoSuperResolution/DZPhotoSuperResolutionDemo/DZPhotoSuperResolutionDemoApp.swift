//
//  DZPhotoSuperResolutionDemoApp.swift
//  DZPhotoSuperResolutionDemo
//
//  Created by Genning.Zhang on 2025/7/17.
//

import SwiftUI

@main
struct DZPhotoSuperResolutionDemoApp: App {
    
    @State private var datas: ContentViewData
    
    init() {
        datas = ContentViewData()
    }
    
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(datas)
        }
    }
}


