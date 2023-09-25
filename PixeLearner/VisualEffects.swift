import SwiftUI

struct VisualEffectBlur<Content: View>: View {
    var blurStyle: UIBlurEffect.Style
    let content: Content?

    init(blurStyle: UIBlurEffect.Style, @ViewBuilder content: () -> Content) {
        self.blurStyle = blurStyle
        self.content = content()
    }

    var body: some View {
        ZStack {
            VisualEffectUIView(blurStyle: blurStyle)
            content
        }
    }
}

struct VisualEffectUIView: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style

    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) {}
}

