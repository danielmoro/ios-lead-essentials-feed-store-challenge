//
//  Copyright © 2020 Essential Developer. All rights reserved.
//

import XCTest
import FeedStoreChallenge

class FeedStoreIntegrationTests: XCTestCase {
	
	//  ***********************
	//
	//  Uncomment and implement the following tests if your
	//  implementation persists data to disk (e.g., CoreData/Realm)
	//
	//  ***********************
	
	override func setUpWithError() throws {
		try super.setUpWithError()
		
		try setupEmptyStoreState()
	}
	
	override func tearDownWithError() throws {
		try undoStoreSideEffects()
		
		try super.tearDownWithError()
	}
	
	func test_retrieve_deliversEmptyOnEmptyCache() throws {
		let sut = try makeSUT()

		expect(sut, toRetrieve: .empty)
	}
	
	func test_retrieve_deliversFeedInsertedOnAnotherInstance() throws {
		let storeToInsert = try makeSUT()
		let storeToLoad = try makeSUT()
		let feed = uniqueImageFeed()
		let timestamp = Date()

		insert((feed, timestamp), to: storeToInsert)

		expect(storeToLoad, toRetrieve: .found(feed: feed, timestamp: timestamp))
	}
	
	func test_insert_overridesFeedInsertedOnAnotherInstance() throws {
		let storeToInsert = try makeSUT()
		let storeToOverride = try makeSUT()
		let storeToLoad = try makeSUT()

		insert((uniqueImageFeed(), Date()), to: storeToInsert)

		let latestFeed = uniqueImageFeed()
		let latestTimestamp = Date()
		insert((latestFeed, latestTimestamp), to: storeToOverride)

		expect(storeToLoad, toRetrieve: .found(feed: latestFeed, timestamp: latestTimestamp))
	}
	
	func test_delete_deletesFeedInsertedOnAnotherInstance() throws {
		let storeToInsert = try makeSUT()
		let storeToDelete = try makeSUT()
		let storeToLoad = try makeSUT()

		insert((uniqueImageFeed(), Date()), to: storeToInsert)

		deleteCache(from: storeToDelete)

		expect(storeToLoad, toRetrieve: .empty)
	}
	
	// - MARK: Helpers
	
	private func makeSUT(file: StaticString = #filePath, line: UInt = #line) throws -> FeedStore {
		let bundle = Bundle(for: CoreDataFeedStore.self)
		let storeURL = testSpecificStoreURL()
		let sut = try CoreDataFeedStore(storeURL: storeURL, modelBundle: bundle)
		trackMemoryLeaks(sut, file: file, line: line)
		return sut
	}
	
	private func testSpecificStoreURL() -> URL {
		let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
		let storeURL = cachesURL.appendingPathComponent("\(type(of: self)).sqlite")
		return storeURL
	}
	
	private func removeCache() {
		try? FileManager.default.removeItem(at: testSpecificStoreURL())
		let shmURL = testSpecificStoreURL().deletingPathExtension().appendingPathComponent(".sqlite-shm")
		let owlURL = testSpecificStoreURL().deletingPathExtension().appendingPathComponent(".sqlite-owl")
		try? FileManager.default.removeItem(at: shmURL)
		try? FileManager.default.removeItem(at: owlURL)
	}
	
	private func setupEmptyStoreState() throws {
		removeCache()
	}
	
	private func undoStoreSideEffects() throws {
		removeCache()
	}
}
