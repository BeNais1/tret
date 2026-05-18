import SwiftUI

struct OnboardingStep2Bio: View {

    @Bindable var viewModel: OnboardingViewModel
    @FocusState private var focused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                StepHeader(
                    title: "Кратко о тебе",
                    subtitle: "Расскажи, чем занимаешься или над чем сейчас работаешь."
                )

                ZStack(alignment: .topLeading) {
                    if viewModel.bio.isEmpty {
                        Text("Например: iOS dev из Минска, делаю pet-проекты на Swift и иногда контрибучу в open-source.")
                            .font(.system(size: 15))
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                    }
                    TextEditor(text: Binding(
                        get: { viewModel.bio },
                        set: { viewModel.bioChanged($0) }
                    ))
                    .font(.system(size: 15))
                    .scrollContentBackground(.hidden)
                    .focused($focused)
                    .frame(minHeight: 180)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(.primary.opacity(0.05), lineWidth: 1)
                )

                HStack {
                    Spacer()
                    Text("\(viewModel.bio.count) / \(AppConstants.maxBioCharacters)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(viewModel.bioRemaining < 0 ? .red : .secondary)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .onAppear { focused = true }
    }
}
