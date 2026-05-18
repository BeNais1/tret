import SwiftUI

struct OnboardingStep3Languages: View {

    @Bindable var viewModel: OnboardingViewModel
    @State private var search = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StepHeader(
                title: "Языки программирования",
                subtitle: "Выбери до \(AppConstants.maxProgrammingLanguages) языков, которые ты знаешь."
            )

            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Поиск", text: $search)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                if !search.isEmpty {
                    Button {
                        search = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            if !viewModel.selectedLanguages.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Выбрано (\(viewModel.selectedLanguages.count)/\(AppConstants.maxProgrammingLanguages))")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    FlowLayout(spacing: 8) {
                        ForEach(viewModel.selectedLanguages, id: \.self) { id in
                            if let lang = ProgrammingLanguage.find(id: id) {
                                LanguageBadgeView(
                                    language: lang,
                                    isSelected: true,
                                    onTap: { viewModel.toggleLanguage(lang) },
                                    onRemove: { viewModel.toggleLanguage(lang) }
                                )
                            }
                        }
                    }
                }
            }

            ScrollView {
                FlowLayout(spacing: 8) {
                    ForEach(ProgrammingLanguage.search(search)) { lang in
                        let isSelected = viewModel.selectedLanguages.contains(lang.id)
                        LanguageBadgeView(
                            language: lang,
                            isSelected: isSelected,
                            onTap: {
                                if isSelected || viewModel.canAddMoreLanguages {
                                    viewModel.toggleLanguage(lang)
                                }
                            }
                        )
                        .opacity(!isSelected && !viewModel.canAddMoreLanguages ? 0.4 : 1.0)
                    }
                }
                .padding(.bottom, 12)
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 16)
    }
}
