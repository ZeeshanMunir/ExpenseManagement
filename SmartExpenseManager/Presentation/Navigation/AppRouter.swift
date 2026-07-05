import Domain
import SwiftUI

struct AppRouter: View {
    @Environment(\.appContainer) private var container
    @State private var path = NavigationPath()
    @State private var expenseToEdit: Expense?

    var body: some View {
        NavigationStack(path: $path) {
            makeExpenseListView()
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .expenseList:
                        makeExpenseListView()

                    case .detail(let expense):
                        ExpenseDetailView(
                            viewModel: ViewModelFactory.makeExpenseDetailViewModel(
                                container: container,
                                expense: expense
                            ),
                            onDeleted: {
                                path.removeLast()
                            },
                            onEdit: { expense in
                                expenseToEdit = expense
                            }
                        )

                    case .addExpense:
                        AddExpenseView(
                            viewModel: ViewModelFactory.makeAddExpenseViewModel(container: container),
                            onSaved: {
                                path.removeLast()
                            }
                        )

                    case .editExpense(let expense):
                        EditExpenseView(
                            viewModel: ViewModelFactory.makeEditExpenseViewModel(
                                container: container,
                                expense: expense
                            ),
                            onSaved: {
                                path.removeLast()
                            }
                        )
                    }
                }
        }
        .sheet(item: $expenseToEdit) { expense in
            NavigationStack {
                EditExpenseView(
                    viewModel: ViewModelFactory.makeEditExpenseViewModel(
                        container: container,
                        expense: expense
                    ),
                    onSaved: {
                        expenseToEdit = nil
                    }
                )
            }
        }
    }

    private func makeExpenseListView() -> ExpenseListView {
        ExpenseListView(
            viewModel: ViewModelFactory.makeExpenseListViewModel(container: container),
            makeAddExpenseViewModel: {
                ViewModelFactory.makeAddExpenseViewModel(container: container)
            },
            makeEditExpenseViewModel: { expense in
                ViewModelFactory.makeEditExpenseViewModel(container: container, expense: expense)
            }
        )
    }
}

#Preview {
    AppRouter()
        .environment(\.appContainer, AppContainer(configuration: .testing()))
}
