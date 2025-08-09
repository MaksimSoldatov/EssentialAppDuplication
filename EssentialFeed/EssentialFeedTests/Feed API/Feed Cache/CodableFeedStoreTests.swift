//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Maxim Soldatov on 9.08.25.
//

import XCTest
import EssentialFeed

final class CodableFeedStore: FeedStore {
    
    func deleteCacheFeed(completion: @escaping DeletionCompletion) {
        fatalError()
    }
    
    func insert(_ feed: [EssentialFeed.LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        fatalError()
    }
    
    func retrieve(completion: @escaping RetrievalCompletion) {
        completion(.success(([], Date())))
    }
}

final class CodableFeedStoreTests: XCTestCase {

    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = CodableFeedStore()
        
        let exp = expectation(description: "Wait for cache retrieval")
        
        sut.retrieve(completion: { result in
            switch result {
            case let .success((feed, _)):
                XCTAssertTrue(feed.isEmpty)
            default:
                XCTFail("Expected empty result, got \(result) instead")
            }
            exp.fulfill()
        })
        
        wait(for: [exp], timeout: 1.0)
        
    }

}
