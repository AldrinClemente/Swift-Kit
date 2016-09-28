//
// HTTP.swift
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

public typealias ResponseHandler = (_ response: Response) -> Void

public struct HTTP {
    fileprivate static let sessionDelegate = SessionDelegate()
    fileprivate static let session: URLSession = URLSession(configuration: URLSessionConfiguration.default, delegate: sessionDelegate, delegateQueue: OperationQueue.main)
    
    public static func request(_ method: Method, url: String, queryParameters: [String : AnyObject] = [:]) -> Request {
        return Request(session: session, method: method, url: url, queryParameters: queryParameters)
    }
    
    public static func request(_ url: String, queryParameters: [String : AnyObject] = [:]) -> Request {
        return request(.GET, url: url, queryParameters:  queryParameters)
    }
    
    public static func setDefaultRequestTimeout(_ seconds: TimeInterval) {
        session.configuration.timeoutIntervalForRequest = seconds
    }
    
    public static func addTrustedHost(_ host: String) {
        sessionDelegate.addTrustedHost(host)
    }
    
    public static func trustAllHosts() {
        sessionDelegate.trustAllHosts()
    }
    
    public static func getQueuedRequests() -> [Request] {
        return Request.requestQueue
    }
    
    public static func clearQueuedRequests() {
        Request.requestQueue.removeAll()
    }
}

class SessionDelegate: NSObject {
    var trustAll: Bool = false
    var trustedHosts: Set<String> = []
    
    func addTrustedHost(_ host: String...) {
        trustedHosts.formUnion(host)
    }
    
    func trustAllHosts() {
        trustAll = true
    }
}

extension SessionDelegate: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        print("Authentication challenge received")
        print("Host: \(challenge.protectionSpace.host)")
        print("Authentication method: \(challenge.protectionSpace.authenticationMethod)")
        
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust
            && (trustAll || trustedHosts.contains(challenge.protectionSpace.host) || task.checkAndConsumeTrust()) {
                print("Host is set as trusted!")
                completionHandler(Foundation.URLSession.AuthChallengeDisposition.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
        } else {
            print("Host is not set as trusted, performing default handling...")
            completionHandler(Foundation.URLSession.AuthChallengeDisposition.performDefaultHandling, nil)
        }
    }
}
