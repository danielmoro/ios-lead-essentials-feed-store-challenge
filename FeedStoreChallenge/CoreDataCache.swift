//
//  Created by Daniel Moro on 26.3.21.
//  Copyright © 2021 Essential Developer. All rights reserved.
//  
//

import Foundation
import CoreData

public class CoreDataCache: NSManagedObject,Identifiable {
	
	@NSManaged public var date: Date
	@NSManaged public var feed: NSOrderedSet?
	
	@objc(insertObject:inFeedAtIndex:)
	@NSManaged public func insertIntoFeed(_ value: CoreDataFeedImage, at idx: Int)

	@objc(removeObjectFromFeedAtIndex:)
	@NSManaged public func removeFromFeed(at idx: Int)

	@objc(insertFeed:atIndexes:)
	@NSManaged public func insertIntoFeed(_ values: [CoreDataFeedImage], at indexes: NSIndexSet)

	@objc(removeFeedAtIndexes:)
	@NSManaged public func removeFromFeed(at indexes: NSIndexSet)

	@objc(replaceObjectInFeedAtIndex:withObject:)
	@NSManaged public func replaceFeed(at idx: Int, with value: CoreDataFeedImage)

	@objc(replaceFeedAtIndexes:withFeed:)
	@NSManaged public func replaceFeed(at indexes: NSIndexSet, with values: [CoreDataFeedImage])

	@objc(addFeedObject:)
	@NSManaged public func addToFeed(_ value: CoreDataFeedImage)

	@objc(removeFeedObject:)
	@NSManaged public func removeFromFeed(_ value: CoreDataFeedImage)

	@objc(addFeed:)
	@NSManaged public func addToFeed(_ values: NSOrderedSet)

	@objc(removeFeed:)
	@NSManaged public func removeFromFeed(_ values: NSOrderedSet)
	
	@nonobjc public class func fetchRequest() -> NSFetchRequest<CoreDataCache> {
		return NSFetchRequest<CoreDataCache>(entityName: "CoreDataCache")
	}
}

extension CoreDataCache {
	var localFeed: [LocalFeedImage] {
		guard let feed = feed?.array as? [CoreDataFeedImage] else {
			return []
		}

		return feed.compactMap(\.local)
	}
	
	static func fetch(in context: NSManagedObjectContext) throws -> CoreDataCache? {
		let fetchRequest: NSFetchRequest<CoreDataCache> = self.fetchRequest()
		let fetchResult = try context.fetch(fetchRequest)
		return fetchResult.first
	}
	
	static func delete(in context: NSManagedObjectContext) throws {
		if let cache = try self.fetch(in: context) {
			context.delete(cache)
		}
	}
	
	static func make(from feed: [LocalFeedImage], timestamp: Date, in context: NSManagedObjectContext) {
		let cache = self.init(context: context)
		cache.date = timestamp
		cache.feed = NSOrderedSet(array: feed.map { CoreDataFeedImage($0, insertInto: context) })
	}
}

