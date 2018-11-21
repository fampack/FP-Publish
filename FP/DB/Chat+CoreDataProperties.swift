//
//  Chat+CoreDataProperties.swift
//  FP
//
//  Created by Bajrang on 08/23/18.
//  Copyright © 2018 Bajrang. All rights reserved.
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension Chat {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Chat> {
        return NSFetchRequest<Chat>(entityName: "Chat");
    }

    @NSManaged public var chatId: String?
    @NSManaged public var chatMessage: String?
    @NSManaged public var chatSenderId: String?
    @NSManaged public var chatSenderName: String?
    @NSManaged public var chatStatus: String?
    @NSManaged public var chatTimeStamp: Double
    @NSManaged public var convoId: String?
    @NSManaged public var mediaLength: String?
    @NSManaged public var mediaType: String?
    @NSManaged public var mediaUrlOriginal: String?
    @NSManaged public var mediaUrlThumb: String?
    @NSManaged public var relationship: Conversation?

}
