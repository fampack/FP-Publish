//
//  Conversation+CoreDataProperties.swift
//  FP
//
//  Created by Bajrang on 08/23/18.
//  Copyright © 2018 Bajrang. All rights reserved.
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension Conversation {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Conversation> {
        return NSFetchRequest<Conversation>(entityName: "Conversation");
    }

    @NSManaged public var chatMessage: String?
    @NSManaged public var chatSenderId: String?
    @NSManaged public var convoId: String?
    @NSManaged public var isChatOpen: Bool
    @NSManaged public var isOtherUserOnline: Bool
    @NSManaged public var lastMessagetime: Double
    @NSManaged public var lastModifiedTime: Double
    @NSManaged public var otherUserId: String?
    @NSManaged public var otherUserName: String?
    @NSManaged public var typing: String?
    @NSManaged public var unReadCount: String?
    @NSManaged public var userId: String?
    @NSManaged public var imgUrl: String?
    @NSManaged public var relationship: NSOrderedSet?

}

// MARK: Generated accessors for relationship
extension Conversation {

    @objc(insertObject:inRelationshipAtIndex:)
    @NSManaged public func insertIntoRelationship(_ value: Chat, at idx: Int)

    @objc(removeObjectFromRelationshipAtIndex:)
    @NSManaged public func removeFromRelationship(at idx: Int)

    @objc(insertRelationship:atIndexes:)
    @NSManaged public func insertIntoRelationship(_ values: [Chat], at indexes: NSIndexSet)

    @objc(removeRelationshipAtIndexes:)
    @NSManaged public func removeFromRelationship(at indexes: NSIndexSet)

    @objc(replaceObjectInRelationshipAtIndex:withObject:)
    @NSManaged public func replaceRelationship(at idx: Int, with value: Chat)

    @objc(replaceRelationshipAtIndexes:withRelationship:)
    @NSManaged public func replaceRelationship(at indexes: NSIndexSet, with values: [Chat])

    @objc(addRelationshipObject:)
    @NSManaged public func addToRelationship(_ value: Chat)

    @objc(removeRelationshipObject:)
    @NSManaged public func removeFromRelationship(_ value: Chat)

    @objc(addRelationship:)
    @NSManaged public func addToRelationship(_ values: NSOrderedSet)

    @objc(removeRelationship:)
    @NSManaged public func removeFromRelationship(_ values: NSOrderedSet)

}
