//
//  Created by Daniel Moro on 26.3.21.
//  Copyright © 2021 Essential Developer. All rights reserved.
//  
//

import Foundation
import CoreData

class CoreDataFeedImage: NSManagedObject, Identifiable {
	
	@NSManaged var id: UUID
	@NSManaged var imageDescription: String?
	@NSManaged var location: String?
	@NSManaged var url: URL
	@NSManaged var cache: CoreDataCache
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
