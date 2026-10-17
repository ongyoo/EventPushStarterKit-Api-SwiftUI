//
//  GlassShapes.swift
//  LiquidGlassKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import UIKit

/// Masks drawn once per corner radius and stretched (9-slice resizable images),
/// so a glass view can animate its size without redrawing anything.
@MainActor
enum GlassShapes {
    private static var cache: [String: UIImage] = [:]

    /// Opaque at the rim, fading to clear `depth` points inside: where the lens bends light.
    static func rimFalloff(cornerRadius radius: CGFloat, depth: CGFloat) -> UIImage {
        let radius = max(radius.rounded(), 1)
        let depth = min(depth, radius)
        let key = "rim-\(radius)-\(depth)"
        if let image = cache[key] { return image }
        let side = radius * 2 + 2
        let size = CGSize(width: side, height: side)
        let image = UIGraphicsImageRenderer(size: size).image { context in
            let steps = 20
            let ring = depth / CGFloat(steps)
            for step in 0..<steps {
                let progress = CGFloat(step) / CGFloat(steps)
                let inset = depth * progress + ring / 2
                let rect = CGRect(origin: .zero, size: size).insetBy(dx: inset, dy: inset)
                guard rect.width > 0 else { break }
                // Quadratic falloff: strong right at the edge, gone further in.
                context.cgContext.setStrokeColor(UIColor(white: 1, alpha: pow(1 - progress, 2)).cgColor)
                context.cgContext.setLineWidth(ring + 0.5)
                context.cgContext.addPath(UIBezierPath(roundedRect: rect, cornerRadius: max(radius - inset, 0)).cgPath)
                context.cgContext.strokePath()
            }
        }
        return store(stretchable(image, radius: radius), key: key)
    }

    /// Filled rounded rect, stretchable: the clip shape of a glass view.
    static func fill(cornerRadius radius: CGFloat) -> UIImage {
        let radius = max(radius.rounded(), 1)
        let key = "fill-\(radius)"
        if let image = cache[key] { return image }
        let side = radius * 2 + 2
        let image = UIGraphicsImageRenderer(size: CGSize(width: side, height: side)).image { _ in
            UIColor.white.setFill()
            UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: side, height: side), cornerRadius: radius).fill()
        }
        return store(stretchable(image, radius: radius), key: key)
    }

    private static func stretchable(_ image: UIImage, radius: CGFloat) -> UIImage {
        image.resizableImage(
            withCapInsets: UIEdgeInsets(top: radius, left: radius, bottom: radius, right: radius),
            resizingMode: .stretch
        )
    }

    private static func store(_ image: UIImage, key: String) -> UIImage {
        if cache.count > 40 { cache.removeAll() }
        cache[key] = image
        return image
    }
}
