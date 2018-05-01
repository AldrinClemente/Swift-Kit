//
// Request.swift
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

open class Request {
    var session: URLSession!
    var task: URLSessionTask!
    var request: URLRequest!
    var response: Response?
    var responseHandler: ResponseHandler?
    var isTrustedHost: Bool = false
    var logTag: String?
    
    var bodyProvider: (() -> Data)?
    
    var mockResponse: MockResponse?
    
    static var requestQueue: [Request] = []
    static var pendingRequest: Request?
    
    init(session: URLSession, method: Method, url: String, queryParameters: [String : AnyObject] = [:]) {
        self.session = session
        
        let encodedURL = queryParameters.count > 0 ? "\(url)?\(queryParameters.stringFromQueryParameters)" : url
        
        if let url = URL(string: encodedURL) {
            request = URLRequest(url: url)
        }
        
        request.httpMethod = method.rawValue
    }
    
    open func setResponseHandler(_ responseHandler: @escaping ResponseHandler) -> Self {
        self.responseHandler = responseHandler
        return self
    }
    
    open func addHeader(_ key: String, value: String) -> Self {
        request.addValue(value, forHTTPHeaderField: key)
        return self
    }
    
    open func addHeaders(_ headers: [String: String]) -> Self {
        for (key, value) in headers {
            request.addValue(value, forHTTPHeaderField: key)
        }
        return self
    }
    
    open func setHeader(_ key: String, value: String) -> Self {
        request.setValue(value, forHTTPHeaderField: key)
        return self
    }
    
    open func setHeaders(_ headers: [String: String]) -> Self {
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        return self
    }
    
    open func setTimeout(_ seconds: TimeInterval) -> Self {
        request.timeoutInterval = seconds
        return self
    }
    
    open func setBody(_ body: JSON) -> Self {
        do {
            request.httpBody = try body.rawData()
        } catch {
            // TODO
        }
        return self
    }
    
    open func setBody(_ body: Data) -> Self {
        request.httpBody = body
        return self
    }
    
    open func setBody(_ body: MultiPartContent) -> Self {
        request.httpBody = body.data
        return addHeader("Content-Type", value: "multipart/form-data;boundary=\(body.boundary)")
    }
    
    open func setBody(_ body: String) -> Self {
        request.httpBody = body.data(using: String.Encoding.utf8)
        return self
    }
    
    open func setBodyProvider(_ provider: @escaping () -> Data) -> Self {
        bodyProvider = provider
        return self
    }
    
    open func setMockResponse(_ mockResponse: MockResponse) -> Self {
        self.mockResponse = mockResponse
        self.mockResponse?.originalRequest = self
        return self
    }
    
    open func setLogTag(_ tag: String) -> Self {
        self.logTag = tag
        return self
    }
    
    open func trustHost() -> Self {
        isTrustedHost = true
        return self
    }
    
    open func queue() -> Self {
        Request.requestQueue.append(self)
        executeFromQueueIfFree()
        return self
    }
    
    open func execute() -> Self {
        if let bProvider = bodyProvider {
            request.httpBody = bProvider()
        }
        task = session.dataTask(with: request, completionHandler: handleResponse)
        if isTrustedHost {
            task.trustHost()
            print("\(logTag!) SSL Verification Disabled **********")
        }
        if let lTag = logTag {
            if let endpoint = request.url?.absoluteString {
                print("\(lTag) Endpoint: \(endpoint)")
            }
            for (k, v) in request.allHTTPHeaderFields! {
                print("\(lTag) Request Header: \(k): \(v)")
            }
            if let body = request.httpBody?.utf8EncodedString {
                print("\(lTag) Request Body: \(body)")
            } else {
                print("\(lTag) Request Body: nil")
            }
        }
        if (mockResponse == nil) {
            task.resume()
        } else {
            Async.runOnBackgroundThread(1, task: nil) {
                self.handleResponse(response: self.mockResponse)
            }
        }
        return self
    }
    
    open func cancel() -> Self {
        task.cancel()
        return self
    }
    
    open func suspend() -> Self {
        task.suspend()
        return self
    }
    
    fileprivate func executeFromQueueIfFree() {
        if Request.pendingRequest == nil && Request.requestQueue.count > 0 {
            Request.pendingRequest = Request.requestQueue.removeFirst()
            _ = Request.pendingRequest?.execute()
        }
    }
    
    fileprivate func handleResponse(_ data: Data?, response: URLResponse?, error: Error?) {
        self.response = Response(originalRequest: self, data: data, httpResponse: response as? HTTPURLResponse, error: error)
        handleResponse(response: self.response)
    }
    
    private func handleResponse(response: Response?) {
        if let lTag = logTag {
            if let statusMessage = response?.statusMessage {
                print("\(lTag) Response Message: \(statusMessage)")
            } else {
                print("\(lTag) Response Message: nil")
            }
            if let content = response!.data?.utf8EncodedString {
                print("\(lTag) Response Content: \(content)")
            } else {
                print("\(lTag) Response Content: nil")
            }
        }
        responseHandler?(response!)
        if let pendingRequest = Request.pendingRequest {
            if pendingRequest === self {
                Request.pendingRequest = nil
                executeFromQueueIfFree()
            }
        }
    }
}

extension URLSessionTask {
    func trustHost() {
        TrustedTaskHostsHolder.trustedHosts[taskIdentifier] = true
    }
    
    func checkAndConsumeTrust() -> Bool {
        return TrustedTaskHostsHolder.trustedHosts.removeValue(forKey: taskIdentifier) ?? false
    }
    
    fileprivate class TrustedTaskHostsHolder {
        static var trustedHosts: [Int : Bool] = [:]
    }
}


open class MultiPartContent {
    var boundary: String = "*********"
    var parts: [Part] = []
    open var data: Data {
        var data: Data = Data()
        for part in parts {
            data.appendString("--\(boundary)\r\n")
            data.append(part.data)
        }
        data.appendString("--\(boundary)--\r\n")
        return data as Data
    }
    
    public init() {}
    
    public init(boundary: String) {
        self.boundary = boundary
    }
    
    public init(boundary: String, parts: [Part]) {
        self.boundary = boundary
        self.parts = parts
    }
    
    open func setBoundary(_ boundary: String) {
        self.boundary = boundary
    }
    
    open func addPart(_ part: Part) {
        parts += [part]
    }
    
    open func addPart(_ name: String, value: String, headers: [String : String] = [:]) {
        addPart(Part(name: name, value: value, headers: headers))
    }
    
    open func addPart(_ name: String, data: Data, fileName: String, headers: [String : String] = [:]) {
        addPart(Part(name: name, fileName: fileName, data: data, headers: headers))
    }
    
    open func addPart(_ name: String, path: URL, fileName: String = "", headers: [String : String] = [:]) {
        if let data = try? Data(contentsOf: path) {
            addPart(name, data: data, fileName: fileName != "" ? fileName : path.lastPathComponent, headers: headers)
        }
    }
    
    public struct Part {
        var data: Data = Data()
        
        init(name: String, fileName: String, data: Data, headers: [String : String] = [:]) {
            self.data.appendString("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(fileName)\"\r\n")
            for (key, value) in headers {
                self.data.appendString("\(key): \(value)\r\n")
            }
            self.data.appendString("\r\n")
            self.data.append(data)
            self.data.appendString("\r\n")
        }
        
        init(name: String, value: String, headers: [String : String] = [:]) {
            self.data.appendString("Content-Disposition: form-data; name=\"\(name)\"\r\n")
            for (key, value) in headers {
                self.data.appendString("\(key): \(value)\r\n")
            }
            self.data.appendString("\r\n")
            self.data.appendString(value)
            self.data.appendString("\r\n")
        }
    }
}


public enum Method: String, CustomStringConvertible {
    case OPTIONS, GET, HEAD, POST, PUT, PATCH, DELETE, TRACE
    
    public var description : String {
        get {
            return self.rawValue
        }
    }
}


public enum RequestError: Error {
    case timeout
    case appTransportSecurity
    case serverAuthenticationFailed
    case clientAuthenticationFailed
    case noNetworkConnection
    case other(error: URLError)
}
