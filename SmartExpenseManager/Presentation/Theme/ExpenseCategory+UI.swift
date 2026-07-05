import Domain
import SwiftUI

extension ExpenseCategory {
    var displayName: String {
        switch self {
        case .food: return "Food"
        case .transport: return "Transport"
        case .shopping: return "Shopping"
        case .entertainment: return "Entertainment"
        case .bills: return "Bills"
        case .health: return "Health"
        case .travel: return "Travel"
        case .other: return "Other"
        }
    }

    var iconName: String {
        switch self {
        case .food: return "fork.knife"
        case .transport: return "car.fill"
        case .shopping: return "bag.fill"
        case .entertainment: return "film.fill"
        case .bills: return "doc.text.fill"
        case .health: return "heart.fill"
        case .travel: return "airplane"
        case .other: return "ellipsis.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .food: return .orange
        case .transport: return .blue
        case .shopping: return .purple
        case .entertainment: return .pink
        case .bills: return .red
        case .health: return .green
        case .travel: return .cyan
        case .other: return .gray
        }
    }
}
