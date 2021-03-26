//
//  Created by Daniel Moro on 26.3.21.
//  Copyright © 2021 Essential Developer. All rights reserved.
//  
//

import Foundation
import CoreData

class CoreDataCache: NSManagedObject {
	
	@NSManaged var date: Date
	@NSManaged var feed: NSOrderedSet?
	
	@NSManaged func insertIntoFeed(_ value: CoreDataFeedImage, at idx: Int)
	
	@nonobjc class func fetchRequest() -> NSFetchRequest<CoreDataCache> {
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

