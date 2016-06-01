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

public class Request {
    var session: NSURLSession!
    var task: NSURLSessionTask!
    var request: NSMutableURLRequest!
    var response: Response?
    var responseHandler: ResponseHandler?
    var isTrustedHost: Bool = false
    var logTag: String?
    
    var bodyProvider: (() -> NSData)?
    
    static var requestQueue: [Request] = []
    static var pendingRequest: Request?
    
    init(session: NSURLSession, method: Method, url: String, queryParameters: [String : AnyObject] = [:]) {
        self.session = session
        
        let encodedURL = queryParameters.count > 0 ? "\(url)?\(queryParameters.stringFromQueryParameters)" : url
        
        request = NSMutableURLRequest(URL: NSURL(string: encodedURL)!)
        request.HTTPMethod = method.rawValue
    }
    
    public func handleResponse(responseHandler: ResponseHandler) -> Self {
        self.responseHandler = responseHandler
        return self
    }
    
    public func addHeader(key: String, value: String) -> Self {
        request.addValue(value, forHTTPHeaderField: key)
        return self
    }
    
    public func addHeaders(headers: [String: String]) -> Self {
        for (key, value) in headers {
            request.addValue(value, forHTTPHeaderField: key)
        }
        return self
    }
    
    public func setHeader(key: String, value: String) -> Self {
        request.setValue(value, forHTTPHeaderField: key)
        return self
    }
    
    public func setHeaders(headers: [String: String]) -> Self {
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        return self
    }
    
    public func setTimeout(seconds: NSTimeInterval) -> Self {
        request.timeoutInterval = seconds
        return self
    }
    
    public func setBody(body: JSON) -> Self {
        do {
            request.HTTPBody = try body.rawData()
        } catch {
            // TODO
        }
        return self
    }
    
    public func setBody(body: NSData) -> Self {
        request.HTTPBody = body
        return self
    }
    
    public func setBody(body: MultiPartContent) -> Self {
        request.HTTPBody = body.data
        addHeader("Content-Type", value: "multipart/form-data;boundary=\(body.boundary)")
        return self
    }
    
    public func setBody(body: String) -> Self {
        request.HTTPBody = body.dataUsingEncoding(NSUTF8StringEncoding)
        return self
    }
    
    public func setBodyProvider(provider: () -> NSData) -> Self {
        bodyProvider = provider
        return self
    }
    
    public func setLogTag(tag: String) -> Self {
        self.logTag = tag
        return self
    }
    
    public func trustHost() -> Self {
        isTrustedHost = true
        return self
    }
    
    public func queue() -> Self {
        Request.requestQueue.append(self)
        executeFromQueueIfFree()
        return self
    }
    
    public func execute() -> Self {
        if bodyProvider != nil {
            request.HTTPBody = bodyProvider!()
        }
        task = session.dataTaskWithRequest(request, completionHandler: handleResponse)
        if isTrustedHost {
            task.trustHost()
        }
        if logTag != nil {
            print("\(logTag!) Endpoint: \(request.URL!.absoluteString)")
            for (k, v) in request.allHTTPHeaderFields! {
                print("\(logTag!) Request Header: \(k): \(v)")
            }
            if let body = request.HTTPBody?.utf8EncodedString {
                print("\(logTag!) Request Body: \(body)")
            } else {
                print("\(logTag!) Request Body: nil")
            }
        }
        task.resume()
        return self
    }
    
    public func cancel() -> Self {
        task.cancel()
        return self
    }
    
    public func suspend() -> Self {
        task.suspend()
        return self
    }
    
    private func executeFromQueueIfFree() {
        if Request.pendingRequest == nil && Request.requestQueue.count > 0 {
            Request.pendingRequest = Request.requestQueue.removeFirst()
            Request.pendingRequest!.execute()
        }
    }
    
    private func handleResponse(data: NSData?, response: NSURLResponse?, error: NSError?) {
        self.response = Response(originalRequest: self, data: data, httpResponse: response as? NSHTTPURLResponse, error: error)
        if logTag != nil {
            if let statusMessage = self.response!.statusMessage {
                print("\(logTag!) Response Message: \(statusMessage)")
            } else {
                print("\(logTag!) Response Message: nil")
            }
            if let content = self.response!.data?.utf8EncodedString {
                print("\(logTag!) Response Content: \(content)")
            } else {
                print("\(logTag!) Response Content: nil")
            }
        }
        responseHandler?(response: self.response!)
        if let pendingRequest = Request.pendingRequest {
            if pendingRequest === self {
                Request.pendingRequest = nil
                executeFromQueueIfFree()
            }
        }
    }
}

extension NSURLSessionTask {
    func trustHost() {
        TrustedTaskHostsHolder.trustedHosts[taskIdentifier] = true
    }
    
    func checkAndConsumeTrust() -> Bool {
        return TrustedTaskHostsHolder.trustedHosts.removeValueForKey(taskIdentifier) ?? false
    }
    
    private class TrustedTaskHostsHolder {
        static var trustedHosts: [Int : Bool] = [:]
    }
}


public class MultiPartContent {
    var boundary: String = "*********"
    var parts: [Part] = []
    public var data: NSData {
        let data: NSMutableData = NSMutableData()
        for part in parts {
            data.appendString("--\(boundary)\r\n")
            data.appendData(part.data)
        }
        data.appendString("--\(boundary)--\r\n")
        return data
    }
    
    public init() {}
    
    public init(boundary: String) {
        self.boundary = boundary
    }
    
    public init(boundary: String, parts: [Part]) {
        self.boundary = boundary
        self.parts = parts
    }
    
    public func setBoundary(boundary: String) {
        self.boundary = boundary
    }
    
    public func addPart(part: Part) {
        parts += [part]
    }
    
    public func addPart(name: String, value: String, headers: [String : String] = [:]) {
        addPart(Part(name: name, value: value, headers: headers))
    }
    
    public func addPart(name: String, data: NSData, fileName: String, headers: [String : String] = [:]) {
        addPart(Part(name: name, fileName: fileName, data: data, headers: headers))
    }
    
    public func addPart(name: String, path: NSURL, fileName: String = "", headers: [String : String] = [:]) {
        if let data = NSData(contentsOfURL: path) {
            addPart(name, data: data, fileName: fileName != "" ? fileName : path.lastPathComponent!, headers: headers)
        }
    }
    
    public struct Part {
        var data: NSMutableData = NSMutableData()
        
        init(name: String, fileName: String, data: NSData, headers: [String : String] = [:]) {
            self.data.appendString("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(fileName)\"\r\n")
            for (key, value) in headers {
                self.data.appendString("\(key): \(value)\r\n")
            }
            self.data.appendString("\r\n")
            self.data.appendData(data)
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


public enum RequestError: ErrorType {
    case Timeout
    case AppTransportSecurity
    case ServerAuthenticationFailed
    case ClientAuthenticationFailed
    case NoNetworkConnection
    case Other(error: NSURLError)
}