import SwiftUI

struct AdministrativeSettingControl: View {
    @State private var draftText: String
    @State private var draftNumber: Double
    @State private var isSaving = false
    let setting: AdministrativeSetting
    let stringListOptions: [AdministrativeSettingOption]
    let onSave: (AdministrativeJSONValue) async -> Bool

    init(
        setting: AdministrativeSetting,
        stringListOptions: [AdministrativeSettingOption] = [],
        onSave: @escaping (AdministrativeJSONValue) async -> Bool
    ) {
        self.setting = setting
        self.stringListOptions = stringListOptions
        self.onSave = onSave
        _draftText = State(initialValue: Self.textValue(for: setting.value))
        _draftNumber = State(initialValue: setting.value.numberValue ?? setting.constraints?.minimum ?? 0)
    }

    var body: some View {
        switch setting.controlKind {
        case .boolean:
            Toggle(isOn: booleanBinding) {
                settingLabel
            }
            .disabled(isSaving)
        case .integer:
            #if os(tvOS)
                numericButtonControl(step: integerStep, fractionLength: 0)
            #else
                LabeledContent {
                    Stepper(
                        draftNumber.formatted(.number.precision(.fractionLength(0))),
                        value: $draftNumber,
                        in: numericRange,
                        step: integerStep
                    )
                    .onChange(of: draftNumber) { _, value in
                        Task { await save(.number(value.rounded())) }
                    }
                    .disabled(isSaving)
                } label: {
                    settingLabel
                }
            #endif
        case .decimal:
            #if os(tvOS)
                numericButtonControl(step: decimalStep, fractionLength: 2)
            #else
                VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                    HStack {
                        settingLabel
                        Spacer()
                        Text(draftNumber.formatted(.number.precision(.fractionLength(2))))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    Slider(
                        value: $draftNumber,
                        in: numericRange,
                        step: decimalStep
                    ) { editing in
                        if !editing { Task { await save(.number(draftNumber)) } }
                    }
                    .disabled(isSaving)
                }
            #endif
        case .select:
            LabeledContent {
                Picker(setting.label, selection: selectionBinding) {
                    ForEach(setting.options) { option in
                        Text(option.label).tag(option.value)
                    }
                }
                .labelsHidden()
                .disabled(isSaving)
            } label: {
                settingLabel
            }
        case .text:
            VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                settingLabel
                #if os(tvOS)
                    TextField(setting.label, text: $draftText)
                        .prismediaTextInputStyle(surface: .embedded)
                        .onSubmit { Task { await saveText() } }
                        .disabled(isSaving)
                #else
                    TextField(setting.label, text: $draftText, axis: .vertical)
                        .lineLimit(1...2)
                        .prismediaTextInputStyle(surface: .embedded)
                        .onSubmit { Task { await saveText() } }
                        .disabled(isSaving)
                #endif
                Button("Save \(setting.label)") { Task { await saveText() } }
                    .disabled(isSaving || draftValue == setting.value)
            }
        case .stringList:
            AdministrativeStringListControl(
                setting: setting,
                options: stringListOptions,
                onSave: onSave
            )
        case .unsupported:
            LabeledContent(setting.label, value: setting.value.displayValue)
                .foregroundStyle(.secondary)
        }
    }

    private var settingLabel: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.extraExtraSmall) {
            Text(setting.label)
            Text(setting.applyHint.map { "\(setting.description) \($0)" } ?? setting.description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var booleanBinding: Binding<Bool> {
        Binding(
            get: { setting.value.boolValue ?? false },
            set: { value in Task { await save(.bool(value)) } }
        )
    }

    private var selectionBinding: Binding<String> {
        Binding(
            get: { setting.value.stringValue ?? "" },
            set: { value in Task { await save(.string(value)) } }
        )
    }

    private var numericRange: ClosedRange<Double> {
        let minimum = setting.constraints?.minimum ?? (setting.controlKind == .decimal ? 0 : 1)
        let maximum = setting.constraints?.maximum ?? (setting.controlKind == .decimal ? 100 : 9_999)
        return minimum...max(minimum, maximum)
    }

    private var integerStep: Double {
        max(1, setting.constraints?.step ?? 1)
    }

    private var decimalStep: Double {
        max(0.0001, setting.constraints?.step ?? 0.05)
    }

    #if os(tvOS)
        private func numericButtonControl(step: Double, fractionLength: Int) -> some View {
            HStack {
                settingLabel
                Spacer()
                Button("Decrease", systemImage: "minus") { adjustNumber(by: -step) }
                    .labelStyle(.iconOnly)
                    .disabled(isSaving || draftNumber <= numericRange.lowerBound)
                Text(draftNumber.formatted(.number.precision(.fractionLength(fractionLength))))
                    .monospacedDigit()
                    .frame(minWidth: 90)
                Button("Increase", systemImage: "plus") { adjustNumber(by: step) }
                    .labelStyle(.iconOnly)
                    .disabled(isSaving || draftNumber >= numericRange.upperBound)
            }
        }

        private func adjustNumber(by amount: Double) {
            draftNumber = min(max(draftNumber + amount, numericRange.lowerBound), numericRange.upperBound)
            Task { await save(.number(draftNumber)) }
        }
    #endif

    private var draftValue: AdministrativeJSONValue {
        return .string(draftText.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private func saveText() async {
        await save(draftValue)
    }

    private func save(_ value: AdministrativeJSONValue) async {
        guard value != setting.value else { return }
        isSaving = true
        defer { isSaving = false }
        if !(await onSave(value)) {
            draftText = Self.textValue(for: setting.value)
            draftNumber = setting.value.numberValue ?? draftNumber
        }
    }

    private static func textValue(for value: AdministrativeJSONValue) -> String {
        switch value {
        case .string(let value): value
        case .stringList: ""
        default: ""
        }
    }

}

#if DEBUG
    #Preview("Setting Control") {
        Form {
            AdministrativeSettingControl(setting: AdministrativePreviewService.setting) { _ in true }
        }
    }
#endif
