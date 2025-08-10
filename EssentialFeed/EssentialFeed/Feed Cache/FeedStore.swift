//
//  FeedStore.swift
//  EssentialFeed
//
//  Created by Maxim Soldatov on 8.08.25.
//

import Foundation

public protocol FeedStore {
    
    typealias DeletionCompletion = (Result<Void, Error>) -> Void
    typealias InsertionCompletion = (Result<Void, Error>) -> Void
    typealias RetrievalCompletion = (Result<(feed: [LocalFeedImage], timestamp: Date?), Error>) -> Void
    
    func deleteCacheFeed(completion: @escaping DeletionCompletion)
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion)
    
    func retrieve(completion: @escaping RetrievalCompletion)
}
