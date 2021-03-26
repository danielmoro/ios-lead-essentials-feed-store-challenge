//
//  Created by Daniel Moro on 26.3.21.
//  Copyright © 2021 Essential Developer. All rights reserved.
//  
//

import Foundation
import CoreData

public class CoreDataFeedImage: NSManagedObject, Identifiable {
	
	@NSManaged public var id: UUID
	@NSManaged public var imageDescription: String?
	@NSManaged public var location: String?
	@NSManaged public var url: URL
	@NSManaged public var cache: CoreDataCache
	
	@nonobjc public class func fetchRequest() -> NSFetchRequest<CoreDataFeedImage> {
		return NSFetchRequest<CoreDataFeedImage>(entityName: "CoreDataFeedImage")
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
		return LocalFeedImage(id: id, description: imageDescription, location: location, url: url)
	}
}
