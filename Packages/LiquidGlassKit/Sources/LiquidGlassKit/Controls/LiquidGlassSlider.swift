//
//  LiquidGlassSlider.swift
//  LiquidGlassKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import SwiftUI

/// iOS 26 slider: while dragging, the thumb grows into a glass lens over the
/// track. iOS 26 shows the system `Slider` (already glass).
///
///     LiquidGlassSlider(value: $volume, in: 0...1)
public struct LiquidGlassSlider: View {
    @Binding private var value: Double
    private let range: ClosedRange<Double>
    private let step: Double?
    @GestureState private var isDragging = false
    @Environment(\.isEnabled) private var isEnabled

    public init(value: Binding<Double>, in range: ClosedRange<Double> = 0...1, step: Double? = nil) {
        self._value = value
        self.range = range
        self.step = step
    }

    public var body: some View {
        if LiquidGlass.isSystemDesign {
            if let step {
                Slider(value: $value, in: range, step: step)
            } else {
                Slider(value: $value, in: range)
            }
        } else {
            kitSlider
        }
    }

    private var progress: CGFloat {
        let span = range.upperBound - range.lowerBound
        return span > 0 ? CGFloat((value - range.lowerBound) / span) : 0
    }

    private var kitSlider: some View {
        GeometryReader { proxy in
            let thumb = CGSize(width: isDragging ? 40 : 28, height: isDragging ? 26 : 28)
            let usable = max(proxy.size.width - 28, 1)
            let x = 14 + usable * progress
            ZStack(alignment: .leading) {
                Capsule().fill(Color(uiColor: .systemFill)).frame(height: 6)
                Capsule().fill(.tint).frame(width: x, height: 6)
                Capsule()
                    .fill(isDragging ? AnyShapeStyle(.clear) : AnyShapeStyle(Color.white))
                    .frame(width: thumb.width, height: thumb.height)
                    .liquidGlass(isDragging ? .clear : .regular, in: .capsule)
                    .shadow(color: .black.opacity(isDragging ? 0.08 : 0.2), radius: 3, y: 1)
                    .scaleEffect(isDragging ? 1.25 : 1)
                    .position(x: x, y: proxy.size.height / 2)
            }
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($isDragging) { _, state, _ in state = true }
                    .onChanged { drag in
                        let fraction = min(max((drag.location.x - 14) / usable, 0), 1)
                        var newValue = range.lowerBound + Double(fraction) * (range.upperBound - range.lowerBound)
                        if let step, step > 0 {
                            newValue = (newValue / step).rounded() * step
                        }
                        value = min(max(newValue, range.lowerBound), range.upperBound)
                    }
            )
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: isDragging)
        }
        .frame(height: 36)
        .opacity(isEnabled ? 1 : 0.45)
        .accessibilityElement()
        .accessibilityValue(Text("\(Int((progress * 100).rounded())) percent"))
        .accessibilityAdjustableAction { direction in
            let delta = step ?? (range.upperBound - range.lowerBound) / 10
            switch direction {
            case .increment: value = min(value + delta, range.upperBound)
            case .decrement: value = max(value - delta, range.lowerBound)
            @unknown default: break
            }
        }
    }
}
