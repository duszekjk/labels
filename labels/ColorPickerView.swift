//
//  ColorPickerView.swift
//  labels
//
//  Created by Jacek Kałużny on 03/02/2025.
//


import SwiftUI

struct ColorPickerView: View {
    @Binding var image: UIImage?
    @Binding var objectColors: [Color]
    @Binding var backgroundColors: [Color]
    @Binding var presentationMode: Bool
    
    @State private var isSelectingObjectColors = true
    @State private var isSwitchingNext = true
    @State private var selectedColors: [Color] = []
    
    var body: some View {
        ZStack {
            if(isSwitchingNext)
            {
                    Text(isSelectingObjectColors ? "Select 20 Object Colors" : "Select 20 Background Colors")
                        .font(.title)
                        .onAppear()
                {
                    DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 1.0, execute:
                                                                            {
                        DispatchQueue.main.async {
                            isSwitchingNext = false
                        }
                        
                    })
                }
            }
            else
            {
                VStack
                {
                    GeometryReader { geometry in
                        Image(uiImage: image!)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(15)
                            .gesture(DragGesture(minimumDistance: 0)
                                .onEnded { value in
                                    let location = value.location
                                    let convertedLocation = CGPoint(
                                        x: location.x * (image!.size.width / geometry.size.width),
                                        y: location.y * (image!.size.width / geometry.size.width)
                                    )
                                    
                                    if let pickedColor = pickColor(from: image!, at: convertedLocation) {
                                        if selectedColors.count < 20 {
                                            selectedColors.append(pickedColor)
                                        }
                                        if selectedColors.count == 20 {
                                            if isSelectingObjectColors {
                                                objectColors = selectedColors
                                                selectedColors.removeAll()
                                                isSelectingObjectColors = false
                                            } else {
                                                backgroundColors = selectedColors
                                                presentationMode = false
                                            }
                                            isSwitchingNext = true
                                        }
                                    }
                                }
                            )
                    }
                    Spacer()
                }
            }
            VStack
            {
                Spacer()
                List {
                    Text(isSelectingObjectColors ? "Select 20 Object Colors" : "Select 20 Background Colors")
                        .font(.headline)
                        .opacity(0.9)
                    HStack {
                        ForEach(selectedColors.indices, id: \.self) { index in
                            VStack {
                                ColorPicker(isSelectingObjectColors ? "": "", selection: $selectedColors[index])
                            }
                        }
                    }
                    .opacity(0.9)
                    HStack {
                        Spacer()
                        ForEach(objectColors.indices, id: \.self) { index in
                            VStack {
                                ColorPicker("", selection: $objectColors[index])
                            }
                        }
                        Spacer()
                    }
                    .opacity(0.9)
                    HStack {
                        Spacer()
                        ForEach(backgroundColors.indices, id: \.self) { index in
                            VStack {
                                ColorPicker("", selection: $backgroundColors[index])
                            }
                        }
                        Spacer()
                    }
                    .opacity(0.9)
                }
                .padding(.top, -20)
                .padding(.bottom, -5)
                .frame(height: 200)
                .cornerRadius(15)
                .opacity(0.7)
            }
        }
        .frame(minHeight: 900)
    }
    
    func pickColor(from image: UIImage, at location: CGPoint) -> Color? {
        print(location.debugDescription)
        guard let cgImage = image.cgImage else { return nil }
//        let scale = image.size.width / UIScreen.main.bounds.width
        let x = Int(location.x)
        let y = Int(location.y)
        guard let pixelColor = cgImage.color(atX: x, y: y) else { return nil }
        return Color(pixelColor)
    }
}

extension CGImage {
    func color(atX x: Int, y: Int) -> UIColor? {
        guard let dataProvider = self.dataProvider,
              let data = dataProvider.data else { return nil }
        let pixelData = CFDataGetBytePtr(data)
        let bytesPerPixel = 4
        let index = (y * self.width + x) * bytesPerPixel
        guard index + 3 < CFDataGetLength(data) else { return nil }
        guard let pixelData = pixelData else { return nil }
        return UIColor(
            red: CGFloat(pixelData[index]) / 255.0,
            green: CGFloat(pixelData[index + 1]) / 255.0,
            blue: CGFloat(pixelData[index + 2]) / 255.0,
            alpha: 1.0
        )
    }
}
