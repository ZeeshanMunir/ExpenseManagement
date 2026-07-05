import CoreData
import Foundation

public protocol EntityMapping {
    associatedtype ManagedObject: NSManagedObject
    associatedtype Record

    static func toRecord(_ object: ManagedObject) -> Record?
    static func update(_ object: ManagedObject, from record: Record)
}

public extension EntityMapping {
    static func makeOrUpdate(
        in context: NSManagedObjectContext,
        from record: Record,
        fetch: (NSManagedObjectContext) throws -> ManagedObject?
    ) throws -> ManagedObject {
        let object = try fetch(context) ?? ManagedObject(context: context)
        update(object, from: record)
        return object
    }
}
