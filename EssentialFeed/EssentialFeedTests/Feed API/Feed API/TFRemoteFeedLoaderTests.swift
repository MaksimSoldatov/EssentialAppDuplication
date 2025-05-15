//
// TFRemoteFeedLoaderTests.swift created 31.03.25.
//

import Testing
import Foundation
import EssentialFeed

struct TFRemoteFeedLoaderTests {

    @Test func init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
        #expect(client.requestedURLs.isEmpty)
    }

    @Test func load_requestDataFromURL() async {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)

        _ = try? await sut.load()

        #expect(client.requestedURLs == [url])
    }
    
    @Test func loadTwice_requestsDataFromURLTwice() async {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        _ = try? await sut.load()
        _ = try? await sut.load()
        
        #expect(client.requestedURLs == [url, url])
    }
    
    @Test func load_deliversErrorOnClientError() async {
        let (sut, client) = makeSUT()
        
        client.mockError()
        
        await expect(sut,
                     toCompleteWith: .failure(.connectivity),
                     sourceLocation: .init(fileID: #fileID, filePath: #filePath, line: #line, column: #column))
    }
    
    @Test func load_deliversErrorOnNon200HTTPStatusCodes() async {
        let (sut, client) = makeSUT()
        let non200StatusCodes = [199, 201, 300, 400, 500]
        
        for statusCode in non200StatusCodes {
            client.mockResponse(withStatusCode: statusCode)
            await expect(sut,
                         toCompleteWith: .failure(.invalidData),
                         sourceLocation: .init(fileID: #fileID, filePath: #filePath, line: #line, column: #column)
            )
        }
    }
    
    @Test func load_deliversErrorOn200HTTPResponseWithInvalidJSON() async {
        let (sut, client) = makeSUT()

        let invalidJSON = Data("Invalid JSON".utf8)
        client.mockResponse(withStatusCode: 200, data: invalidJSON)
        
        await expect(sut,
                     toCompleteWith: .failure(.invalidData),
                     sourceLocation: .init(fileID: #fileID, filePath: #filePath, line: #line, column: #column)
        )
    }
    
    @Test func load_deliversNoItemsOn200HTTPResponseWithEmptyJSON() async {
        let (sut, client) = makeSUT()
        let emptyJSON = "{\"items\": []}".data(using: .utf8)!
        client.mockResponse(withStatusCode: 200, data: emptyJSON)
        await expect(sut,
                     toCompleteWith: .success([]),
                     sourceLocation: .init(fileID: #fileID, filePath: #filePath, line: #line, column: #column)
        )
    }
    
    @Test func load_deliversItemsOn200HTTPResponseWithValidJSON() async {
        let (sut, client) = makeSUT()
        
        let item1 = FeedItem(id: UUID(),
                             description: nil,
                             location: nil,
                             imageURL: URL(string: "https://a-url2.com")!)
        let item1Json = [
            "id": item1.id.uuidString,
            "image": item1.imageURL.absoluteString
        ]
        
        let item2 = FeedItem(id: UUID(),
                             description: "a description",
                             location: "a location",
                             imageURL: URL(string: "https://a-url.com")!)
        let item2Json = [
            "id": item2.id.uuidString,
            "description": item2.description,
            "location": item2.location,
            "image": item2.imageURL.absoluteString
        ]
        
        let json: [String: Any] = [
            "items": [item1Json, item2Json]
        ]
        
        let jsonData = try! JSONSerialization.data(withJSONObject: json)
        client.mockResponse(withStatusCode: 200, data: jsonData)
        await expect(sut,
                     toCompleteWith: .success([item1, item2]),
                     sourceLocation: .init(fileID: #fileID, filePath: #filePath, line: #line, column: #column))
    }

    // MARK: - Helpers

    private func makeSUT(url: URL = URL(string: "https://a-url.com")!) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
    }
    
    private func expect(_ sut: RemoteFeedLoader,
                        toCompleteWith expectedResult: RemoteFeedLoader.Result,
                        sourceLocation: SourceLocation) async {
        
        var capturedResult: RemoteFeedLoader.Result?
       
        do {
            let items = try await sut.load()
            capturedResult = .success(items)
        } catch let error {
            capturedResult = .failure(error as! RemoteFeedLoader.Error)
        }
        
        switch (capturedResult, expectedResult) {
        case (.success(let capturedItems), .success(let expectedItems)):
            #expect(capturedItems == expectedItems, sourceLocation: sourceLocation)
        case (.failure(let capturedError), .failure(let expectedError)):
            #expect(capturedError == expectedError, sourceLocation: sourceLocation)
        default:
            Issue.record("Expected success but got failure", sourceLocation: sourceLocation)
        }
    }

    private class HTTPClientSpy: HTTPClient {
        
        private let defaultError = NSError(domain: "test", code: 0, userInfo: nil)
        
        var mockError: Error?
        var mockResponse: (data: Data, response: HTTPURLResponse)?
        var requestedURLs = [URL]()
        
        func get(from url: URL) async throws -> (data: Data, response: HTTPURLResponse) {
            requestedURLs.append(url)
            
            if let mockError = mockError {
                throw mockError
            }
            
            if let mockResponse = mockResponse {
                return mockResponse
            }
            
            throw defaultError
        }
        
        func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) {
            Issue.record("Will be tested in separate file")
        }
        
        func mockError(_ error: Error? = NSError(domain: "test", code: 1, userInfo: nil)) {
            self.mockError = error
        }
        
        func mockResponse(withStatusCode code: Int, data: Data = Data(), url: URL = URL(string: "https://a-url.com")!) {
            let response = HTTPURLResponse(url: url,
                                           statusCode: code,
                                           httpVersion: nil,
                                           headerFields: nil)!
            mockResponse = (data, response)
        }
    }
}
