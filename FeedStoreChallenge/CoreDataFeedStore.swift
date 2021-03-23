//
//  Created by Daniel Moro on 23.3.21.
//  Copyright © 2021 Essential Developer. All rights reserved.
//  

import CoreData

public class CoreDataFeedStore: FeedStore {
	
	enum Error: Swift.Error {
		case modelNotFound
	}
	
	private var container: NSPersistentContainer
	private var context: NSManagedObjectContext
	
	public init(storeURL: URL, modelBundle: Bundle = Bundle.main) throws {
		guard let modelURL = modelBundle.url(forResource: "CoreDataFeedModel", withExtension: "momd"),
			  let model = NSManagedObjectModel(contentsOf: modelURL) else {
			throw Error.modelNotFound
		}
		
		container = NSPersistentContainer(name: "CoreDataFeedModel", managedObjectModel: model)
		container.persistentStoreDescriptions = [NSPersistentStoreDescription(url: storeURL)]
		container.loadPersistentStores(completionHandler: {_,_ in})
		context = container.newBackgroundContext()
	}
	
	public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
		
	}
	
	public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
		context.perform { [unowned self] in
			let fetchRequest: NSFetchRequest<CoreDataCache> = CoreDataCache.fetchRequest()
			let fetchResult = try? self.context.fetch(fetchRequest)
			if let cache = fetchResult?.first {
				self.context.delete(cache)
			}
			
			_ = CoreDataCache(feed: feed, timestamp: timestamp, insertInto: context)
			try? self.context.save()
			completion(nil)
		}
	}
	
	public func retrieve(completion: @escaping RetrievalCompletion) {
		context.perform { [unowned self] in
			let fetchRequest: NSFetchRequest<CoreDataCache> = CoreDataCache.fetchRequest()
			let fetchResult = try? self.context.fetch(fetchRequest)
			if let cache = fetchResult?.first, let timestamp = cache.date {
				completion(.found(feed: cache.localFeed, timestamp: timestamp))
			} else {
				completion(.empty)
			}
		}
	}
}

extension CoreDataFeedImage {
	convenience init(_ image: LocalFeedImage, insertInto context: NSManagedObjectContext) {
		self.init(context: context)
		id = image.id
		imageDescription = image.description
		location = image.location
		url = image.url
	}
	
	var local: LocalFeedImage? {
		guard let id = id, let url = url else {
			return nil
		}
		
		return LocalFeedImage(id: id, description: imageDescription, location: location, url: url)
	}
}

extension CoreDataCache {
	convenience init(feed: [LocalFeedImage], timestamp: Date, insertInto context: NSManagedObjectContext) {
		self.init(context: context)
		date = timestamp
		self.feed = NSOrderedSet(array: feed.map { CoreDataFeedImage($0, insertInto: context) })
	}

	var localFeed: [LocalFeedImage] {
		guard let feed = feed?.array as? [CoreDataFeedImage] else {
			return []
		}

		return feed.compactMap(\.local)
	}
}
