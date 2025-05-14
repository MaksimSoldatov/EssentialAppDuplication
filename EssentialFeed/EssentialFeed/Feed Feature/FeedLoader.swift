//
//  Copyright © Essential Developer. All rights reserved.
//

import Foundation

public protocol FeedLoader {
    typealias Result = Swift.Result<[FeedItem], RemoteFeedLoader.Error>
    func load(completion: @escaping (Result) -> Void)
    
    func load() async throws  -> [FeedItem]
}
