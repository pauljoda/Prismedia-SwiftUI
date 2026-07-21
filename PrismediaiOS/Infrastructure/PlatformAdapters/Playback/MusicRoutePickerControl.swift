#if os(iOS)
    import AVKit
    import SwiftUI

    struct MusicRoutePickerControl: UIViewRepresentable {
        func makeUIView(context: Context) -> AVRoutePickerView {
            let view = AVRoutePickerView(frame: .zero)
            view.prioritizesVideoDevices = false
            view.tintColor = .white
            view.activeTintColor = .white
            return view
        }

        func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
    }

    #if DEBUG
        #Preview("Music Route Picker Control") {
            MusicRoutePickerControl()
                .frame(
                    width: PrismediaLayout.minimumHitTarget - (PrismediaSpacing.small * 2),
                    height: PrismediaLayout.minimumHitTarget - (PrismediaSpacing.small * 2)
                )
                .padding(PrismediaSpacing.small)
                .background(.black)
        }
    #endif
#endif
