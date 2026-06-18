//
//  CDAnime+CoreDataProperties.swift
//  MYStream
//
//  Created by Arthur da Rosa-Peters / PBD2H24A on 18.06.26.
//
//

public import Foundation
public import CoreData


public typealias CDAnimeCoreDataPropertiesSet = NSSet

extension CDAnime {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDAnime> {
        return NSFetchRequest<CDAnime>(entityName: "CDAnime")
    }

    @NSManaged public var coverURL: String?
    @NSManaged public var dateAdded: String?
    @NSManaged public var episodeCount: Int16
    @NSManaged public var genreList: String?
    @NSManaged public var hasDub: Bool
    @NSManaged public var hasSub: Bool
    @NSManaged public var id: Int64
    @NSManaged public var isAvailable: Bool
    @NSManaged public var isFinished: Bool
    @NSManaged public var isNew: Bool
    @NSManaged public var isOnWatchlist: Bool
    @NSManaged public var localCoverURL: String?
    @NSManaged public var summary: String?
    @NSManaged public var title: String?
    @NSManaged public var episodes: NSSet?

}

// MARK: Generated accessors for episodes
extension CDAnime {

    @objc(addEpisodesObject:)
    @NSManaged public func addToEpisodes(_ value: CDEpisode)

    @objc(removeEpisodesObject:)
    @NSManaged public func removeFromEpisodes(_ value: CDEpisode)

    @objc(addEpisodes:)
    @NSManaged public func addToEpisodes(_ values: NSSet)

    @objc(removeEpisodes:)
    @NSManaged public func removeFromEpisodes(_ values: NSSet)

}

extension CDAnime : Identifiable {

}
