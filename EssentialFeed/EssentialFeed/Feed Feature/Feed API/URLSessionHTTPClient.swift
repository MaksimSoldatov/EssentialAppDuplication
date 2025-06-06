//
// URLSessionHTTPClient.swift created 14.05.25.
//

import Foundation

public class URLSessionHTTPClient: HTTPClient {
    
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    private struct UnexpectedValuesRepresentation: Error {}

    public func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) {
        session.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
            } else if let data = data, let response = response as? HTTPURLResponse {
                completion(.success((data, response)))
            } else {
                completion(.failure(UnexpectedValuesRepresentation()))
            }
        }.resume()
    }
    
    public func get(from url: URL) async throws -> (data: Data, response: HTTPURLResponse) {
        let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw UnexpectedValuesRepresentation()
            }
            
            return (data, httpResponse)
    }
}
