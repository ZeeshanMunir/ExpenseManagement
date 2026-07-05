import Domain
import SwiftUI

struct SyncStatusBadge: View {
    enum Style {
        case standard
        case compact
    }

    let status: ExpenseSyncStatus
    var style: Style = .standard

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.caption2.weight(.semibold))
            if style == .standard {
                Text(title)
                    .font(.caption2.weight(.medium))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
        .foregroundStyle(foregroundColor)
        .padding(.horizontal, style == .compact ? 5 : 6)
        .padding(.vertical, 2)
        .background(foregroundColor.opacity(0.12), in: Capsule())
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityLabel(title)
    }

    private var title: String {
        switch status {
        case .synced: L10n.syncStatusSynced
        case .pending: L10n.syncStatusPending
        case .failed: L10n.syncStatusFailed
        }
    }

    private var systemImage: String {
        switch status {
        case .synced: "checkmark.icloud"
        case .pending: "arrow.triangle.2.circlepath.icloud"
        case .failed: "exclamationmark.icloud"
        }
    }

    private var foregroundColor: Color {
        switch status {
        case .synced: .green
        case .pending: .orange
        case .failed: .red
        }
    }
}
