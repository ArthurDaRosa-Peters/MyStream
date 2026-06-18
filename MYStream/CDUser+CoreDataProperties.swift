//
//  CDUser+CoreDataProperties.swift
//  MYStream
//
//  Created by Arthur da Rosa-Peters / PBD2H24A on 18.06.26.
//
//

public import Foundation
public import CoreData


public typealias CDUserCoreDataPropertiesSet = NSSet

extension CDUser {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDUser> {
        return NSFetchRequest<CDUser>(entityName: "CDUser")
    }

    @NSManaged public var isLoggedIn: Bool
    @NSManaged public var username: String?

}

extension CDUser : Identifiable {

}
