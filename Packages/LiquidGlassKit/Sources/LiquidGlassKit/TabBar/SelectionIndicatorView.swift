//
//  SelectionIndicatorView.swift
//  LiquidGlassKit
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import UIKit

/// The mark under the selected tab, drawn for each `Selection.Style`.
/// `.glass` is a small raised piece of glass: soft gradient, rim light on top,
/// a faint shadow under it, so the selection floats inside the bar.
@MainActor
final class SelectionIndicatorView: UIView {
    private(set) var style: LiquidGlassTabBarAppearance.Selection.Style = .glass
    private var color: UIColor = .systemBlue
    private var fixedRadius: CGFloat?

    private let fill = CAGradientLayer()
    private let rim = CAShapeLayer()
    private let rimMask = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        layer.cornerCurve = .continuous
        fill.cornerCurve = .continuous
        layer.addSublayer(fill)
        rim.fillColor = nil
        rim.lineWidth = 1
        rim.mask = rimMask
        // Rim light strongest at the top, fading toward the bottom.
        rimMask.colors = [UIColor.white.cgColor, UIColor.white.withAlphaComponent(0.25).cgColor]
        layer.addSublayer(rim)
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: SelectionIndicatorView, _) in
            view.updateColors()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported") // lint:allow – marked unavailable, can never be called
    }

    func configure(style: LiquidGlassTabBarAppearance.Selection.Style, color: UIColor, cornerRadius: CGFloat?) {
        self.style = style
        self.color = color
        self.fixedRadius = cornerRadius
        isHidden = style == .none
        updateColors()
        setNeedsLayout()
    }

    /// The indicator's frame inside a tab whose frame is `tab`.
    static func frame(for style: LiquidGlassTabBarAppearance.Selection.Style, in tab: CGRect, inset: UIEdgeInsets) -> CGRect {
        switch style {
        case .glass, .tint, .solid, .none:
            return tab.inset(by: inset)
        case .underline:
            return CGRect(x: tab.midX - 11, y: tab.maxY - 5, width: 22, height: 3)
        case .dot:
            return CGRect(x: tab.midX - 2.5, y: tab.maxY - 7, width: 5, height: 5)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 1, bounds.height > 1 else { return }
        let radius = min(fixedRadius ?? bounds.height / 2, bounds.height / 2, bounds.width / 2)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.cornerRadius = radius
        fill.frame = bounds
        fill.cornerRadius = radius
        rim.frame = bounds
        rimMask.frame = bounds
        rim.path = UIBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), cornerRadius: max(radius - 0.5, 0)).cgPath
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: radius).cgPath
        CATransaction.commit()
    }

    private func updateColors() {
        let dark = traitCollection.userInterfaceStyle == .dark
        let color = color.resolvedColor(with: traitCollection)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        rim.isHidden = style != .glass
        layer.shadowOpacity = 0
        switch style {
        case .glass:
            // Lighter at the top like a lens catching light.
            fill.colors = dark
                ? [UIColor(white: 1, alpha: 0.22).cgColor, UIColor(white: 1, alpha: 0.1).cgColor]
                : [UIColor(white: 1, alpha: 0.95).cgColor, UIColor(white: 0.97, alpha: 0.75).cgColor]
            rim.strokeColor = UIColor.white.withAlphaComponent(dark ? 0.35 : 1).cgColor
            layer.shadowOpacity = dark ? 0.35 : 0.1
            layer.shadowRadius = 6
        case .tint:
            let soft = color.withAlphaComponent(dark ? 0.28 : 0.16).cgColor
            fill.colors = [soft, soft]
        case .solid, .underline, .dot:
            fill.colors = [color.cgColor, color.cgColor]
            if style == .solid {
                layer.shadowOpacity = 0.25
                layer.shadowRadius = 6
                layer.shadowColor = color.cgColor
            }
        case .none:
            fill.colors = [UIColor.clear.cgColor, UIColor.clear.cgColor]
        }
        if style != .solid { layer.shadowColor = UIColor.black.cgColor }
        CATransaction.commit()
    }
}
