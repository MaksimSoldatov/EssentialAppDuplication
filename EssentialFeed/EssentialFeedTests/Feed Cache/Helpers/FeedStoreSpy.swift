//
//  FeedStoreSpy.swift
//  EssentialFeedTests
//
//  Created by Maxim Soldatov on 8.08.25.
//

import Foundation
import EssentialFeed

final class FeedStoreSpy: FeedStore {

    enum ReceivedMessages: Equatable {
        case deleteCachedFeed
        case insert(feed: [LocalFeedImage], timestamp: Date)
        case retrieve
    }
    
    private var deletionCompletions = [DeletionCompletion]()
    private var insertionCompletions = [InsertionCompletion]()
    private var retrievalCompletions = [RetrievalCompletion]()
    private(set) var receivedMessages = [ReceivedMessages]()
    
    func deleteCachedFeed(_ completion: @escaping DeletionCompletion) {
        deletionCompletions.append(completion)
        receivedMessages.append(.deleteCachedFeed)
    }
    
    func completeDeletionSuccessfully(at index: Int = 0) {
        deletionCompletions[index](.success(()))
    }
    
    func completeDeletion(with error: NSError, at index: Int = 0) {
        deletionCompletions[index](.failure(error))
    }
    
    func insert(_ feed: [LocalFeedImage], timestamp: Date, _ completion: @escaping InsertionCompletion) {
        insertionCompletions.append(completion)
        receivedMessages.append(.insert(feed: feed, timestamp: timestamp))
    }
    
    func completeInsertion(with error: NSError, at index: Int = 0) {
        insertionCompletions[index](.failure(error))
    }
    
    func completeInsertionSuccessfully(at index: Int = 0) {
        insertionCompletions[index](.success(()))
    }
    
    func retrieve(_ completion: @escaping RetrievalCompletion) {
        retrievalCompletions.append(completion)
        receivedMessages.append(.retrieve)
    }
    
    func completeRetrieval(with result: Result<[LocalFeedImage], Error>,
                           timestamp: Date = Date(),
                           at index: Int = 0) {
        switch result {
        case .success(let feed):
            retrievalCompletions[index](.success((feed, timestamp)))
        case .failure(let error):
            retrievalCompletions[index](.failure(error))
        }
    }
}
