import Domain
import SwiftUI

struct ExpenseFormView: View {
    @Binding var form: ExpenseFormData

    var body: some View {
        Form {
            Section(L10n.formDetailsSection) {
                TextField(L10n.formTitlePlaceholder, text: $form.title)
                    .textInputAutocapitalization(.words)
                    .accessibilityLabel(L10n.formTitlePlaceholder)

                TextField(L10n.formAmountPlaceholder, text: $form.amountText)
                    .keyboardType(.decimalPad)
                    .accessibilityLabel(L10n.formAmountPlaceholder)

                DatePicker(L10n.formDateLabel, selection: $form.date, displayedComponents: .date)
            }

            Section(L10n.formCategorySection) {
                Picker(L10n.formCategoryLabel, selection: $form.category) {
                    ForEach(ExpenseCategory.allCases, id: \.self) { category in
                        Label(category.displayName, systemImage: category.iconName)
                            .tag(category)
                    }
                }
                .pickerStyle(.navigationLink)
            }

            Section(L10n.formNoteSection) {
                TextField(L10n.formNotePlaceholder, text: $form.note, axis: .vertical)
                    .lineLimit(3...6)
            }
        }
        .scrollContentBackground(.hidden)
    }
}
