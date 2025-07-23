//
//  DZSwiftUIHelper.swift
//  DZPhotoSuperResolutionDemo
//
//  Created by Genning.Zhang on 2025/7/17.
//

import SwiftUI

struct DZHudModifier: ViewModifier {
    @Binding var isShown: Bool
    let message: String
    
    init(isShown: Binding<Bool>, message: String = "处理中...") {
        self._isShown = isShown
        self.message = message
    }
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isShown {
                Color.black.opacity(0.6)
                     .ignoresSafeArea()
                     .overlay {
                         VStack(spacing: 20) {
                             ProgressView()
                                 .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                 .scaleEffect(1.5)
                             
                             Text(message)
                                 .foregroundColor(.white)
                                 .font(.title2)
                                 .fontWeight(.medium)
                         }
                         .padding(40)
                         .background(
                             RoundedRectangle(cornerRadius: 12)
                                 .fill(Color.black.opacity(0.8))
                         )
                     }
            }
        }
    }
}

struct DZAlertModifier: ViewModifier {
    
    @Binding var alertMessage: String?
    
    func body(content: Content) -> some View {
        content.alert("", isPresented: .constant(alertMessage != nil)) {
            Button("确定") { alertMessage = nil }
        } message: {
            Text(alertMessage ?? "")
        }
    }
}

struct DZShareModifier: ViewModifier {
    @Binding var isSharePresented: Bool
    
    let items: [Any]
    
    func body(content: Content) -> some View {
        if items.isEmpty {
            content
        } else {
            content.sheet(isPresented: $isSharePresented) {
                ActivityViewController(activityItems: items)
            }
        }
    }
}

struct DZImagePreviewView: View {

    var image: UIImage? = nil
    var title: String
    var placeholder: String
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                VStack(spacing: 16.0) {
                    Image(systemName: placeholder)
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
        .background(Color.gray.opacity(0.3))
    }
}

extension View {

    func HUD(isShown: Binding<Bool>, message: String) -> some View {
        self.modifier(DZHudModifier(isShown: isShown, message: message))
    }
    
    func ErrorAlert(message: Binding<String?>) -> some View {
        self.modifier(DZAlertModifier(alertMessage: message))
    }
    
    func share(isShown: Binding<Bool>, items: [Any]) -> some View {
        self.modifier(DZShareModifier(isSharePresented: isShown, items: items))
    }
}
