//
//  Posts.swift
//  MySampleApp
//
//
// Copyright 2017 Amazon.com, Inc. or its affiliates (Amazon). All Rights Reserved.
//
// Code generated by AWS Mobile Hub. Amazon gives unlimited permission to 
// copy, distribute and modify it.
//
// Source code generated from template: aws-my-sample-app-ios-swift v0.19
//

import Foundation
import UIKit
import AWSDynamoDB

class Posts: AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    
    var _postId: String?
    var _dateTime: String?
    var _imageurl: [String: String]?
    var _postType: String?
    var _taggedusers: [String]?
    var _text: String?
    var _userId: String?
    var _videourl: [String: String]?
    
    class func dynamoDBTableName() -> String {

        return "betus-mobilehub-1316247808-posts"
    }
    
    class func hashKeyAttribute() -> String {

        return "_postId"
    }
    
    override class func jsonKeyPathsByPropertyKey() -> [AnyHashable: Any] {
        return [
               "_postId" : "postId",
               "_dateTime" : "dateTime",
               "_imageurl" : "imageurl",
               "_postType" : "postType",
               "_taggedusers" : "taggedusers",
               "_text" : "text",
               "_userId" : "userId",
               "_videourl" : "videourl",
        ]
    }
}