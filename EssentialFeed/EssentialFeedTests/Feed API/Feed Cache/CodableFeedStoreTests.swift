//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Maxim Soldatov on 9.08.25.
//

import XCTest
import EssentialFeed

final class CodableFeedStore: FeedStore {
    
    private struct CodableFeedImage: Codable {
        
        private let id: UUID
        private let description: String?
        private let location: String?
        private let url: URL
        
        init(_ image: LocalFeedImage) {
            id = image.id
            description = image.description
            location = image.location
            url = image.url
        }

        var local: LocalFeedImage {
            .init(id: id, description: description, location: location, url: url)
        }
    }
    
    private struct Cache: Codable {
        let feed: [CodableFeedImage]
        let timestamp: Date
        
        var localFeed: [LocalFeedImage] {
            feed.map({ $0.local })
        }
    }
    
    private let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("image-feed.store")
    
    func deleteCacheFeed(completion: @escaping DeletionCompletion) {

    }
    
    func insert(_ feed: [EssentialFeed.LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        let encoder = JSONEncoder()
        let cache = Cache(feed: feed.map(CodableFeedImage.init), timestamp: timestamp)
        let encoded = try! encoder.encode(cache)
        try! encoded.write(to: storeURL)
        completion(.success(()))
    }
    
    func retrieve(completion: @escaping RetrievalCompletion) {
        guard let data = try? Data(contentsOf: storeURL) else {
            return completion(.success(([], nil)))
        }
        
        let decoder = JSONDecoder()
        let cache = try! decoder.decode(Cache.self, from: data)
        completion(.success((cache.localFeed, timestamp: cache.timestamp)))
    }
}

final class CodableFeedStoreTests: XCTestCase {
    
    override func setUp() {
        super.setUp()

        let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("image-feed.store")
        try? FileManager.default.removeItem(at: storeURL)
    }

    override func tearDown() {
        super.tearDown()

        let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("image-feed.store")
        try? FileManager.default.removeItem(at: storeURL)
    }

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
    
    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        let sut = CodableFeedStore()
        let exp = expectation(description: "Wait for cache retrieval")

        sut.retrieve { firstResult in
            sut.retrieve { secondResult in
                switch (firstResult, secondResult) {
                case let (.success((feed1, _)), .success((feed2, _))):
                    XCTAssertTrue(feed1.isEmpty)
                    XCTAssertTrue(feed2.isEmpty)
                default:
                    XCTFail("Expected retrieving twice from empty cache to deliver same empty result, got \(firstResult) and \(secondResult) instead")
                }
                exp.fulfill()
            }
        }

        wait(for: [exp], timeout: 1.0)
    }
    
    func test_retrieveAfterInsertingToEmptyCache_deliversInsertedValues() {
        let sut = CodableFeedStore()
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        let exp = expectation(description: "Wait for cache retrieval")
        
        sut.insert(feed, timestamp: timestamp) { insertResult in
            switch insertResult {
            case .success:
                sut.retrieve { retrieveResult in
                    switch retrieveResult {
                    case let .success((retrievedFeed, retrievedTimestamp)):
                        XCTAssertEqual(retrievedFeed, feed)
                        XCTAssertEqual(retrievedTimestamp, timestamp)
                    case .failure(let error):
                        XCTFail("Expected successful retrieval, got error: \(error)")
                    }
                    exp.fulfill()
                }
            case .failure(let error):
                XCTFail("Expected successful insertion, got error: \(error)")
                exp.fulfill()
            }
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
}
