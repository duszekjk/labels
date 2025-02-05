//
//  ColorSelectionView.swift
//  labels
//
//  Created by Jacek Kałużny on 05/02/2025.
//


import SwiftUI

struct ColorSelectionView: View {
    let title: String
    @Binding var colors: [Color]
    let switchList: () -> Void
    
    @State private var showFullList = false
    
    var body: some View {
        HStack {
            HStack
            {
                Text(title)
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                    .padding(.bottom, 5)
                Spacer()
            }
            .frame(width: 100)
            HStack {
                Spacer()
                
                let visibleColors = colors.prefix(10)
                ForEach(visibleColors.indices, id: \.self) { index in
                    ColorPicker("", selection: $colors[index])
                        .labelsHidden()
                        .scaleEffect(0.75)
                        .padding(.horizontal, -4)
                }
                
                if colors.count > 10 {
                    Text("… and \(colors.count - 10) more")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Button(action: {
                        showFullList.toggle()
                        switchList()
                    }) {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                
                Spacer()
            }
            .opacity(0.9)
            
        }
        .padding(0)
        .sheet(isPresented: $showFullList) {
            FullColorListView(title: title, colors: $colors, show: $showFullList)
        }
    }
}

// Full List View
struct FullColorListView: View {
    let title: String
    
    @Binding var colors: [Color]
    @Binding var show: Bool
    
    var body: some View {
        NavigationView {
            
            List {
                ForEach(colors.indices, id: \.self) { index in
                    HStack {
                        ColorPickerWithLabel(color: $colors[index])
                        Spacer()
                        Button(action: {
                            colors.remove(at: index)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("\(title)")
            .navigationBarItems(trailing: Button(action: {
                show = false
            }, label: {
                Text("Close")
            }))
        }
    }
}
extension Color {
    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components else { return nil }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "%02X%02X%02X", r, g, b)
    }
    
    func toRGBA() -> String {
        guard let components = UIColor(self).cgColor.components else { return "N/A" }
        let r = String(format: "%.2f", components[0])
        let g = String(format: "%.2f", components[1])
        let b = String(format: "%.2f", components[2])
        let a = components.count > 3 ? String(format: "%.2f", components[3]) : "1.00"
        return "RGBA(\(r), \(g), \(b), \(a))"
    }
}
import SwiftUI

struct ColorPickerWithLabel: View {
    @Binding var color: Color

    var body: some View {
        Button(action: {
            // Dummy action – Button opens ColorPicker
        }) {
            HStack {
                let hex = color.toHex() ?? "N/A"
                let rgba = color.toRGBA()

                
                ColorPicker("", selection: $color)
                    .labelsHidden()
                    .frame(width: 0, height: 0) // Hides picker UI but still clickable
                    .padding(10)
                Text("#\(hex) \(rgba)")
                    .foregroundColor(.primary)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 5).fill(Color.white.opacity(0.9)))
                Spacer()
            }
            .background(RoundedRectangle(cornerRadius: 5).fill(Color.white.opacity(0.9)))
        }
        .buttonStyle(PlainButtonStyle()) // Removes button styling
    }
}
