//
//  Users+CoreDataProperties.swift
//  FP
//
//  Created by Bajrang on 08/23/18.
//  Copyright © 2018 Bajrang. All rights reserved.
//

import Foundation
import CoreData


extension Users {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Users> {
        return NSFetchRequest<Users>(entityName: "Users");
    }

    @NSManaged public var userId: String
    @NSManaged public var relationship: NSOrderedSet?

}

// MARK: Generated accessors for relationship
extension Users {

    @objc(insertObject:inRelationshipAtIndex:)
    @NSManaged public func insertIntoRelationship(_ value: Conversation, at idx: Int)

    @objc(removeObjectFromRelationshipAtIndex:)
    @NSManaged public func removeFromRelationship(at idx: Int)

    @objc(insertRelationship:atIndexes:)
    @NSManaged public func insertIntoRelationship(_ values: [Conversation], at indexes: NSIndexSet)

    @objc(removeRelationshipAtIndexes:)
    @NSManaged public func removeFromRelationship(at indexes: NSIndexSet)

    @objc(replaceObjectInRelationshipAtIndex:withObject:)
    @NSManaged public func replaceRelationship(at idx: Int, with value: Conversation)

    @objc(replaceRelationshipAtIndexes:withRelationship:)
    @NSManaged public func replaceRelationship(at indexes: NSIndexSet, with values: [Conversation])

    @objc(addRelationshipObject:)
    @NSManaged public func addToRelationship(_ value: Conversation)

    @objc(removeRelationshipObject:)
    @NSManaged public func removeFromRelationship(_ value: Conversation)

    @objc(addRelationship:)
    @NSManaged public func addToRelationship(_ values: NSOrderedSet)

    @objc(removeRelationship:)
    @NSManaged public func removeFromRelationship(_ values: NSOrderedSet)

}
