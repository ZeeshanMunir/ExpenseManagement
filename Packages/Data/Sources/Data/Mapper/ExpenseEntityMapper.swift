import CoreData
import Domain
import Foundation

enum ExpenseEntityMapper: EntityMapping {
    typealias ManagedObject = ExpenseEntity
    typealias Record = ExpenseRecord

    static func toRecord(_ object: ExpenseEntity) -> ExpenseRecord? {
        guard let id = object.id,
              let title = object.title,
              let date = object.date,
              let createdAt = object.createdAt,
              let updatedAt = object.updatedAt,
              let syncStatusRaw = object.syncStatus,
              let syncStatus = SyncStatus(rawValue: syncStatusRaw) else {
            return nil
        }

        return ExpenseRecord(
            id: id,
            title: title,
            amount: object.amount,
            date: date,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncStatus: syncStatus
        )
    }

    static func update(_ object: ExpenseEntity, from record: ExpenseRecord) {
        object.id = record.id
        object.title = record.title
        object.amount = record.amount
        object.date = record.date
        object.createdAt = record.createdAt
        object.updatedAt = record.updatedAt
        object.syncStatus = record.syncStatus.rawValue
    }

    static func toDomain(_ record: ExpenseRecord) -> Expense {
        Expense(
            id: record.id,
            title: record.title,
            amount: Decimal(record.amount),
            date: record.date,
            syncStatus: record.syncStatus.toDomain()
        )
    }

    static func toRecord(from expense: Expense, syncStatus: SyncStatus = .pending) -> ExpenseRecord {
        ExpenseRecord(
            id: expense.id,
            title: expense.title,
            amount: (expense.amount as NSDecimalNumber).doubleValue,
            date: expense.date,
            syncStatus: syncStatus
        )
    }

    static func toRecord(from dto: ExpenseDTO, syncStatus: SyncStatus = .synced) -> ExpenseRecord {
        let timestamp = dto.updatedAt ?? .now
        return ExpenseRecord(
            id: dto.id,
            title: dto.title,
            amount: dto.amount,
            date: dto.date,
            createdAt: timestamp,
            updatedAt: timestamp,
            syncStatus: syncStatus
        )
    }

    static func toDTO(_ record: ExpenseRecord) -> ExpenseDTO {
        ExpenseDTO(
            id: record.id,
            title: record.title,
            amount: record.amount,
            date: record.date,
            updatedAt: record.updatedAt
        )
    }

    static func toDomain(_ dto: ExpenseDTO) -> Expense {
        Expense(
            id: dto.id,
            title: dto.title,
            amount: Decimal(dto.amount),
            date: dto.date
        )
    }
}
