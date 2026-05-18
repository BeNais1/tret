import SwiftUI

struct LanguagePickerView: View {
    @Binding var selected: [String]
    var maxCount: Int = AppConstants.maxProgrammingLanguages

    @State private var search = ""

    private var canAddMore: Bool { selected.count < maxCount }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            searchField

            if !selected.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Выбрано (\(selected.count)/\(maxCount))")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    FlowLayout(spacing: 8) {
                        ForEach(selected, id: \.self) { id in
                            if let lang = ProgrammingLanguage.find(id: id) {
                                LanguageBadgeView(
                                    language: lang,
                                    isSelected: true,
                                    onTap: { toggle(lang) },
                                    onRemove: { toggle(lang) }
                                )
                            }
                        }
                    }
                }
            }

            FlowLayout(spacing: 8) {
                ForEach(ProgrammingLanguage.search(search)) { lang in
                    let isSelected = selected.contains(lang.id)
                    LanguageBadgeView(
                        language: lang,
                        isSelected: isSelected,
                        onTap: {
                            if isSelected || canAddMore {
                                toggle(lang)
                            }
                        }
                    )
                    .opacity(!isSelected && !canAddMore ? 0.4 : 1.0)
                }
            }
        }
    }

    private var searchField: some View {
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
    }

    private func toggle(_ lang: ProgrammingLanguage) {
        if let index = selected.firstIndex(of: lang.id) {
            selected.remove(at: index)
        } else if canAddMore {
            selected.append(lang.id)
        }
    }
}
