//
//  ProgressViewWithEstimation.swift
//  labels
//
//  Created by Jacek Kałużny on 03/02/2025.
//


import SwiftUI

struct ProgressViewWithEstimation: View {
    let title: String?
    let progress: Double
    let total: Double
    
    @State private var startTime: Date? = nil
    @State private var estimatedTotalTime: TimeInterval? = nil
    
    init(_ title: String? = nil, value: Double, total: Double = 1.0) {
        self.title = title
        self.progress = value
        self.total = total
    }
    init(_ title: String? = nil, value: Float, total: Double = 1.0) {
        self.title = title
        self.progress = Double(value)
        self.total = total
    }
    
    var body: some View {
        VStack {
            if let title = title {
                Text(title)
                    .font(.headline)
            }
            
            ProgressView(value: progress, total: total)
                .padding()
            
            if let estimatedTotalTime = estimatedTotalTime, progress / total > 0.05 {
                VStack {
                    Text("Elapsed: \(formatTime(Date().timeIntervalSince(startTime ?? Date())))")
                    Text("Remaining: \(formatTime(max(0, estimatedTotalTime - (Date().timeIntervalSince(startTime ?? Date())))))")
                    Text("Total Estimated: \(formatTime(estimatedTotalTime))")
                }
                .font(.caption)
                .padding(.top, 5)
            } else {
                Text("Calculating remaining time...")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.top, 5)
            }
        }
        .padding()
        .onAppear { updateEstimations() }
        .onChange(of: progress) { _ in updateEstimations() }
    }
    
    private func updateEstimations() {
        guard progress > 0 else {
            startTime = nil
            return }
        if startTime == nil {
            startTime = Date()
        }
        let elapsedTime = Date().timeIntervalSince(startTime ?? Date())
        if progress / total > 0.05 { // Only estimate if at least 5% progress is reached
            estimatedTotalTime = elapsedTime / (progress / total)
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
