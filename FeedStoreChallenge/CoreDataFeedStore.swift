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
		perform { context in
			do {
				try CoreDataCache.deleteCache(in: context)
				try context.save()
				completion(nil)
			} catch {
				completion(error)
			}
		}
	}
	
	public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
		perform { context in
			do {
				try CoreDataCache.deleteCache(in: context)
				CoreDataCache.make(from: feed, timestamp: timestamp, in: context)
				try context.save()
				completion(nil)
			} catch {
				completion(error)
			}
		}
	}
	
	public func retrieve(completion: @escaping RetrievalCompletion) {
		perform { context in
			do {
				if let cache = try CoreDataCache.fetch(in: context), let timestamp = cache.date {
					completion(.found(feed: cache.localFeed, timestamp: timestamp))
				} else {
					completion(.empty)
				}
			} catch {
				completion(.failure(error))
			}
		}
	}
	
	private func perform(_ action: @escaping(NSManagedObjectContext)->Void) {
		context.perform {
			action(self.context)
		}
	}
}

private extension CoreDataFeedImage {
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

private extension CoreDataCache {
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
	
	static func deleteCache(in context: NSManagedObjectContext) throws {
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
