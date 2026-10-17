//
//  StandardComponents.swift
//  ServerDrivenUI
//
//  Created by Komsit Chusangthong on 17/10/2569 BE.
//

import LiquidGlassKit
import SwiftUI

public extension DynamicComponentRegistry {
    /// Built-in components (see `docs/SCHEMA.md` for every prop):
    ///
    /// Layout: `vstack`, `hstack`, `grid`, `carousel`, `section`, `spacer`, `divider`
    /// Content: `text`, `image`, `icon`, `badge`
    /// Glass: `card`, `glassGroup`, `button`, `banner`, `listItem`, `toolbarButton`
    /// Controls (bound to state): `searchField`, `toggle`, `slider`, `segmented`
    static var standard: DynamicComponentRegistry {
        var registry = DynamicComponentRegistry()
        registry.register("vstack") { c, ctx in
            VStack(alignment: c.horizontalAlignment, spacing: c.cgFloat("spacing") ?? 12) { ctx.render(c.children) }
                .frame(maxWidth: .infinity, alignment: c.frameAlignment)
        }
        registry.register("hstack") { c, ctx in
            HStack(alignment: .center, spacing: c.cgFloat("spacing") ?? 12) { ctx.render(c.children) }
        }
        registry.register("grid") { c, ctx in
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: c.cgFloat("spacing") ?? 12), count: max(Int(c.double("columns") ?? 2), 1)),
                spacing: c.cgFloat("spacing") ?? 12
            ) { ctx.render(c.children) }
        }
        registry.register("carousel") { c, ctx in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: c.cgFloat("spacing") ?? 12) {
                    ForEach(c.children) { child in
                        DynamicComponentView(component: child, context: ctx)
                            .frame(width: c.cgFloat("itemWidth") ?? 260)
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, 16)
            }
            .scrollTargetBehavior(.viewAligned)
            .padding(.horizontal, -16)
        }
        registry.register("section") { c, ctx in
            VStack(alignment: .leading, spacing: 10) {
                if let title = c.string("title") {
                    Text(ctx.state.interpolate(title)).font(.title3.bold()).accessibilityAddTraits(.isHeader)
                }
                if let subtitle = c.string("subtitle") {
                    Text(ctx.state.interpolate(subtitle)).font(.subheadline).foregroundStyle(.secondary)
                }
                ctx.render(c.children)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        registry.register("spacer") { c, _ in
            Spacer(minLength: c.cgFloat("size") ?? 8).frame(height: c.cgFloat("size"))
        }
        registry.register("divider") { _, _ in Divider() }

        registry.register("text") { c, ctx in
            Text(ctx.state.interpolate(c.string("text") ?? ""))
                .font(c.font)
                .foregroundStyle(c.color("color") ?? .primary)
                .multilineTextAlignment(c.textAlignment)
                .lineLimit(c.double("lines").map(Int.init))
                .frame(maxWidth: c.bool("fill") == false ? nil : .infinity, alignment: c.frameAlignment)
        }
        registry.register("image") { c, _ in
            RemoteImageView(component: c)
        }
        registry.register("icon") { c, _ in
            Image(systemName: c.string("systemName") ?? "questionmark")
                .font(.system(size: c.cgFloat("size") ?? 22, weight: .semibold))
                .foregroundStyle(c.color("color").map(AnyShapeStyle.init) ?? AnyShapeStyle(.tint))
                .accessibilityLabel(Text(c.string("label") ?? ""))
                .accessibilityHidden(c.string("label") == nil)
        }
        registry.register("badge") { c, ctx in
            Text(ctx.state.interpolate(c.string("text") ?? ""))
                .font(.caption.weight(.bold))
                .padding(.horizontal, 10).padding(.vertical, 4)
                .foregroundStyle(.white)
                .background(Capsule().fill(c.color("color").map(AnyShapeStyle.init) ?? AnyShapeStyle(.tint)))
        }

        registry.register("card") { c, ctx in
            VStack(alignment: .leading, spacing: c.cgFloat("spacing") ?? 10) { ctx.render(c.children) }
                .padding(c.cgFloat("padding") ?? 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .liquidGlass(.regular.tint(c.color("tint")), in: .rect(cornerRadius: c.cgFloat("cornerRadius") ?? 24))
                .tappable(c, ctx)
        }
        registry.register("glassGroup") { c, ctx in
            LiquidGlassContainer(spacing: c.cgFloat("spacing")) {
                HStack(spacing: c.cgFloat("spacing") ?? 10) { ctx.render(c.children) }
            }
        }
        registry.register("button") { c, ctx in
            DynamicButton(component: c, context: ctx)
        }
        registry.register("banner") { c, ctx in
            BannerView(component: c, context: ctx)
        }
        registry.register("listItem") { c, ctx in
            ListItemView(component: c, context: ctx)
        }
        registry.register("toolbarButton") { c, ctx in
            LiquidGlassToolbarButton(c.string("title") ?? "", systemImage: c.string("icon") ?? "circle") {
                c.action.map(ctx.perform)
            }
        }

        registry.register("searchField") { c, ctx in
            let binding = ctx.binding(c.string("bind"), default: "")
            LiquidGlassSearchField(
                text: Binding(get: { binding.wrappedValue.string ?? "" }, set: { binding.wrappedValue = .string($0) }),
                prompt: c.string("prompt") ?? ""
            ) { c.action.map(ctx.perform) }
        }
        registry.register("toggle") { c, ctx in
            let binding = ctx.binding(c.string("bind"), default: false)
            Toggle(
                ctx.state.interpolate(c.string("title") ?? ""),
                isOn: Binding(get: { binding.wrappedValue.bool ?? false }, set: {
                    binding.wrappedValue = .bool($0)
                    c.action.map(ctx.perform)
                })
            )
            .liquidGlassToggle()
        }
        registry.register("slider") { c, ctx in
            let binding = ctx.binding(c.string("bind"), default: .number(c.double("min") ?? 0))
            VStack(alignment: .leading, spacing: 6) {
                if let title = c.string("title") {
                    Text(ctx.state.interpolate(title)).font(.subheadline.weight(.medium))
                }
                LiquidGlassSlider(
                    value: Binding(get: { binding.wrappedValue.double ?? 0 }, set: { binding.wrappedValue = .number($0) }),
                    in: (c.double("min") ?? 0)...(max(c.double("max") ?? 1, (c.double("min") ?? 0) + 0.0001)),
                    step: c.double("step")
                )
            }
        }
        registry.register("segmented") { c, ctx in
            let binding = ctx.binding(c.string("bind"), default: "")
            let options = c.props["options"]?.array?.compactMap(\.object) ?? []
            LiquidGlassSegmentedPicker(
                selection: Binding(get: { binding.wrappedValue.string ?? "" }, set: {
                    binding.wrappedValue = .string($0)
                    c.action.map(ctx.perform)
                }),
                segments: options.map {
                    .init($0["title"]?.string ?? "", value: $0["value"]?.string ?? "", systemImage: $0["icon"]?.string)
                }
            )
        }
        return registry
    }
}

// MARK: - Components with their own views

private struct DynamicButton: View {
    let component: DynamicComponent
    let context: DynamicRenderContext

    var body: some View {
        let title = context.state.interpolate(component.string("title") ?? "")
        let button = Button {
            component.action.map(context.perform)
        } label: {
            Label {
                Text(title)
            } icon: {
                if let icon = component.string("icon") { Image(systemName: icon) }
            }
            .frame(maxWidth: component.bool("fullWidth") == true ? .infinity : nil)
        }
        switch component.string("style") {
        case "prominent": button.liquidGlassButton(.prominent)
        case "plain": button.buttonStyle(.borderless)
        default: button.liquidGlassButton()
        }
    }
}

private struct BannerView: View {
    let component: DynamicComponent
    let context: DynamicRenderContext

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RemoteImageView(component: component, urlKey: "imageUrl")
            LinearGradient(colors: [.clear, .black.opacity(0.65)], startPoint: .center, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 4) {
                if let badge = component.string("badge") {
                    Text(badge).font(.caption.weight(.bold))
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .liquidGlass(.clear)
                }
                Text(context.state.interpolate(component.string("title") ?? "")).font(.title2.bold())
                if let subtitle = component.string("subtitle") {
                    Text(context.state.interpolate(subtitle)).font(.subheadline)
                }
            }
            .foregroundStyle(.white)
            .padding(16)
        }
        .frame(height: component.cgFloat("height") ?? 200)
        .clipShape(RoundedRectangle(cornerRadius: component.cgFloat("cornerRadius") ?? 26, style: .continuous))
        .accessibilityElement(children: .combine)
        .tappable(component, context)
    }
}

private struct ListItemView: View {
    let component: DynamicComponent
    let context: DynamicRenderContext

    var body: some View {
        HStack(spacing: 14) {
            if let icon = component.string("icon") {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(component.color("iconColor").map(AnyShapeStyle.init) ?? AnyShapeStyle(.tint))
                    .frame(width: 38, height: 38)
                    .liquidGlass(.regular, in: .circle)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(context.state.interpolate(component.string("title") ?? "")).font(.body.weight(.semibold))
                if let subtitle = component.string("subtitle") {
                    Text(context.state.interpolate(subtitle)).font(.subheadline).foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 8)
            if let value = component.string("value") {
                Text(context.state.interpolate(value)).font(.subheadline).foregroundStyle(.secondary)
            }
            if component.action != nil, component.bool("chevron") != false {
                Image(systemName: "chevron.forward").font(.footnote.weight(.semibold)).foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .liquidGlass(.regular, in: .rect(cornerRadius: 20))
        .accessibilityElement(children: .combine)
        .tappable(component, context)
    }
}

private struct RemoteImageView: View {
    let component: DynamicComponent
    var urlKey = "url"

    var body: some View {
        let url = component.string(urlKey).flatMap(URL.init(string:))
        let image = Color.secondary.opacity(0.12)
            .overlay {
                AsyncImage(url: url, transaction: Transaction(animation: .easeOut(duration: 0.25))) { phase in
                    if let image = phase.image {
                        image.resizable().aspectRatio(contentMode: component.string("contentMode") == "fit" ? .fit : .fill)
                    }
                }
            }
            .clipped()
            .frame(maxWidth: .infinity)
            .frame(height: component.cgFloat("height"))
            .clipShape(RoundedRectangle(cornerRadius: component.cgFloat("cornerRadius") ?? 0, style: .continuous))
            .accessibilityLabel(Text(component.string("label") ?? ""))
            .accessibilityHidden(component.string("label") == nil)
        if let ratio = component.cgFloat("aspectRatio") {
            image.aspectRatio(ratio, contentMode: .fit)
        } else {
            image
        }
    }
}

// MARK: - Prop helpers

extension DynamicComponent {
    func cgFloat(_ key: String) -> CGFloat? {
        double(key).map { CGFloat($0) }
    }

    var font: Font {
        let base: Font = switch string("style") {
        case "largeTitle": .largeTitle
        case "title": .title
        case "title2": .title2
        case "title3": .title3
        case "headline": .headline
        case "subheadline": .subheadline
        case "callout": .callout
        case "footnote": .footnote
        case "caption": .caption
        default: .body
        }
        return switch string("weight") {
        case "bold": base.bold()
        case "semibold": base.weight(.semibold)
        case "medium": base.weight(.medium)
        default: base
        }
    }

    var textAlignment: TextAlignment {
        switch string("alignment") {
        case "center": .center
        case "trailing": .trailing
        default: .leading
        }
    }

    var frameAlignment: Alignment {
        switch string("alignment") {
        case "center": .center
        case "trailing": .trailing
        default: .leading
        }
    }

    var horizontalAlignment: HorizontalAlignment {
        switch string("alignment") {
        case "center": .center
        case "trailing": .trailing
        default: .leading
        }
    }

    /// `"#7952FC"`, `"#7952FCCC"` or a name: accent, primary, secondary, red, orange,
    /// yellow, green, teal, blue, purple, pink, gray, white, black.
    func color(_ key: String) -> Color? {
        guard let raw = string(key) else { return nil }
        return DynamicColor.parse(raw)
    }
}

enum DynamicColor {
    static func parse(_ raw: String) -> Color? {
        switch raw.lowercased() {
        case "accent": return .accentColor
        case "primary": return .primary
        case "secondary": return .secondary
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "teal": return .teal
        case "blue": return .blue
        case "purple": return .purple
        case "pink": return .pink
        case "gray": return .gray
        case "white": return .white
        case "black": return .black
        default: break
        }
        var hex = raw.trimmingCharacters(in: .whitespaces)
        guard hex.hasPrefix("#") else { return nil }
        hex.removeFirst()
        guard hex.count == 6 || hex.count == 8, let value = UInt64(hex, radix: 16) else { return nil }
        let hasAlpha = hex.count == 8
        let r = Double((value >> (hasAlpha ? 24 : 16)) & 0xFF) / 255
        let g = Double((value >> (hasAlpha ? 16 : 8)) & 0xFF) / 255
        let b = Double((value >> (hasAlpha ? 8 : 0)) & 0xFF) / 255
        let a = hasAlpha ? Double(value & 0xFF) / 255 : 1
        return Color(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

private extension View {
    /// Whole view tappable when the component has an action.
    @ViewBuilder
    func tappable(_ component: DynamicComponent, _ context: DynamicRenderContext) -> some View {
        if let action = component.action {
            Button { context.perform(action) } label: { self }
                .buttonStyle(PressScaleStyle())
                .accessibilityAddTraits(.isButton)
        } else {
            self
        }
    }
}

private struct PressScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
