//
// MockResponse.swift
//
// Copyright (c) 2016 Aldrin Clemente
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

import Foundation
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l >= r
    default:
        return !(lhs < rhs)
    }
}


public class MockResponse: Response {
    override init(originalRequest: Request?, data: Data?, httpResponse: HTTPURLResponse?, error: Error?) {
        super.init(originalRequest: originalRequest, data: data, httpResponse: httpResponse, error: error)
    }
    
    public class Builder {
        var data: Data?
        var statusCode: Int?
        var headers: [String : String]?
        
        public init() {}
        
        public func setContent(_ data: Data?) -> Self {
            self.data = data
            return self
        }
        
        public func setContent(_ json: JSON?) -> Self {
            self.data = json?.rawString()?.utf8EncodedData
            return self
        }
        
        public func setStatusCode(_ statusCode: Int?) -> Self {
            self.statusCode = statusCode
            return self
        }
        
        public func setHeaders(_ headers: [String : String]) -> Self {
            self.headers = headers
            return self
        }
        
        public func build() -> MockResponse {
            let httpResponse = HTTPURLResponse(url: URL(string: "www.mockresponse.com")!, statusCode: statusCode!, httpVersion: "HTTP/1.1", headerFields: headers)!
            let mockResponse = MockResponse(originalRequest: nil, data: data, httpResponse: httpResponse, error: nil)
            return mockResponse
        }
    }
}
