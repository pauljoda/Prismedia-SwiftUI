#if os(iOS)
    import SwiftUI

    struct MusicRoutePicker: View {
        var body: some View {
            MusicRoutePickerControl()
                .frame(
                    width: PrismediaLayout.minimumHitTarget - (PrismediaSpacing.small * 2),
                    height: PrismediaLayout.minimumHitTarget - (PrismediaSpacing.small * 2)
                )
                .padding(PrismediaSpacing.small)
        }
    }

    #if DEBUG
        #Preview("Music Route Picker") {
            MusicRoutePicker()
                .padding()
                .background(.black)
        }
    #endif
#endif
