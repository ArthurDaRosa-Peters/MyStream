//
//  CDEpisode+CoreDataProperties.swift
//  MYStream
//
//  Created by Arthur da Rosa-Peters / PBD2H24A on 18.06.26.
//
//

public import Foundation
public import CoreData


public typealias CDEpisodeCoreDataPropertiesSet = NSSet

extension CDEpisode {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDEpisode> {
        return NSFetchRequest<CDEpisode>(entityName: "CDEpisode")
    }

    @NSManaged public var completed: Bool
    @NSManaged public var duration: Double
    @NSManaged public var episodeNumber: Int16
    @NSManaged public var id: Int64
    @NSManaged public var isAvailable: Bool
    @NSManaged public var isDownloaded: Bool
    @NSManaged public var isNew: Bool
    @NSManaged public var localFileURL: String?
    @NSManaged public var progress: Double
    @NSManaged public var seasonNumber: Int16
    @NSManaged public var title: String?
    @NSManaged public var anime: CDAnime?

}

extension CDEpisode : Identifiable {

}
