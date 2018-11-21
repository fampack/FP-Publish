//
//  FirebaseConstant.swift
//  FP
//
//  Created by Bajrang on 22/08/18.
//  Copyright © 2017 Bajrang. All rights reserved.
//

import Foundation
import FirebaseDatabase

var ref: DatabaseReference! = Database.database().reference()

let kChild = "Development"
//let kChild = "Live"

let kRegistration = "Registration"

let kUserName = "userName"
let kEmail = "email"
let kAvatarURL = "avatarURL"
let kUserId = "userId"
let kcFriendCount = "friendCount"
let kFcmToken = "fcmToken"

let kFriends = "Friends"
let kFeeds = "Feeds"
let kSharedFeeds = "SharedFeeds"
let kUserInfo = "UserInfo"
let kcConversations = "Conversations"

let kUserImage = "userImage"
let kFeedImages = "feedImages"

let kcCreator = "creator"
let kcCreated = "created"
let kcTitle = "title"
let kcComment = "comment"
let kcFeedImageUrl = "feedImageUrl"
let kcFeedId = "feedId"

let kChatMediaType = "mediaType"
let kChatMessage = "chatMessage"
let kChatSenderId = "chatSenderId"
let kChatStatus = "chatStatus"
let kChatId = "chatId"
let kChatMediaUrlThumb = "mediaUrlThumb"
let kChatSenderName = "chatSenderName"

let kPreffix = "x"

let kcIsChatOpen = "isChatOpen"
let kConversationId = "convoId"
let kIsOtherUserOnline = "isOtherUserOnline"
let kcUsersChat = "UsersChat"
let kcTyping = "IsTyping"
let kcUsers = "Users"
let kcBlockedList = "BlockedList"
let kUnReadCount = "unReadCount"
let kcFavoriteList = "FavoriteList"
let kUserSide = "userSide"
let kOtherSide = "otherSide"
let kLastMessage = "lastMessage"
let kLastMessagetime = "lastMessagetime"
let kLastModifiedTime = "lastModifiedTime"
let kOtherUserId = "otherUserId"
let kOtherUserName = "otherUserName"
let kChatUserType = "userType"
let kisFavorite = "isFavorite"
let kChatInfo = "chatInfo"
let kChatTimeStamp = "chatTimeStamp"
let kChatMediaLength = "mediaLength"
let kChatMediaUrlOriginal = "mediaUrlOriginal"
let kcChat = "Chat"
let kcImage = "Image"
let kcOrginal = "Original"
let kcThumb = "Thumb"

let kUserProfile = "UserProfile"
let kFirstName = "firstName"
let kLastName = "lastName"
let kImageUrl = "imgUrl"
let kOnlineStatus = "onlineStatus"
