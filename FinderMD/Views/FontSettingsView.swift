import SwiftUI

struct FontSettingsView: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        Form {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Font Size")
                    Spacer()
                    Text("\(Int(settings.fontSize)) pt")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Slider(value: $settings.fontSize, in: 12...24, step: 1) {
                    Text("Font Size")
                } minimumValueLabel: {
                    Text("12")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } maximumValueLabel: {
                    Text("24")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text("The quick brown fox jumps over the lazy dog.")
                    .font(.system(size: settings.fontSize))
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.quaternary)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding()
        .navigationTitle("Font")
    }
}
