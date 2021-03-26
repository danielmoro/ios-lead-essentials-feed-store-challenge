//
//  Created by Daniel Moro on 23.3.21.
//  Copyright © 2021 Essential Developer. All rights reserved.
//  

import CoreData

public class CoreDataFeedStore: FeedStore {
	
	enum Error: Swift.Error {
		case modelNotFound
		case loadFailed(Swift.Error)
	}
	
	private var container: NSPersistentContainer
	private var context: NSManagedObjectContext
	private static var modelName: String {
		"CoreDataFeedModel"
	}
	
	public init(storeURL: URL, modelBundle: Bundle = Bundle.main) throws {
		container = try CoreDataFeedStore.loadPersistentContainer(storeURL, bundle: modelBundle)
		context = container.newBackgroundContext()
	}
	
	public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
		perform { context in
			do {
				try CoreDataCache.delete(in: context)
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
				try CoreDataCache.delete(in: context)
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
				if let cache = try CoreDataCache.fetch(in: context) {
					completion(.found(feed: cache.localFeed, timestamp: cache.date))
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
	
	private static func initializePersistentContainer(_ storeURL: URL, bundle: Bundle) throws -> NSPersistentContainer {
		guard let modelURL = bundle.url(forResource: CoreDataFeedStore.modelName, withExtension: "momd"),
			  let model = NSManagedObjectModel(contentsOf: modelURL) else {
			throw Error.modelNotFound
		}
		
		let container = NSPersistentContainer(name: CoreDataFeedStore.modelName, managedObjectModel: model)
		container.persistentStoreDescriptions = [NSPersistentStoreDescription(url: storeURL)]
		
		return container
	}
	
	private static func loadPersistentContainer(_ storeURL: URL, bundle: Bundle) throws -> NSPersistentContainer {
		
		let container = try initializePersistentContainer(storeURL, bundle: bundle)
		
		var loadError: Swift.Error? = nil
		container.loadPersistentStores {_, error in
			loadError = error
		}
		
		if let loadError = loadError {
			throw Error.loadFailed(loadError)
		}
		
		return container
	}
}
