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

public typealias ResponseHandler = (response: Response) -> Void

public struct HTTP {
    private static let sessionDelegate = SessionDelegate()
    private static let session: NSURLSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: sessionDelegate, delegateQueue: NSOperationQueue.mainQueue())
    
    public static func request(method: Method, url: String, queryParameters: [String : AnyObject] = [:]) -> Request {
        return Request(session: session, method: method, url: url, queryParameters: queryParameters)
    }
    
    public static func request(url: String, queryParameters: [String : AnyObject] = [:]) -> Request {
        return request(.GET, url: url, queryParameters:  queryParameters)
    }
    
    public static func setDefaultRequestTimeout(seconds: NSTimeInterval) {
        session.configuration.timeoutIntervalForRequest = seconds
    }
    
    public static func addTrustedHost(host: String) {
        sessionDelegate.addTrustedHost(host)
    }
    
    public static func trustAllHosts() {
        sessionDelegate.trustAllHosts()
    }
}

class SessionDelegate: NSObject {
    var trustAll: Bool = false
    var trustedHosts: Set<String> = []
    
    func addTrustedHost(host: String...) {
        trustedHosts.unionInPlace(host)
    }
    
    func trustAllHosts() {
        trustAll = true
    }
}

extension SessionDelegate: NSURLSessionTaskDelegate {
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        print("Authentication challenge received")
        print("Host: \(challenge.protectionSpace.host)")
        print("Authentication method: \(challenge.protectionSpace.authenticationMethod)")
        
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust
            && (trustAll || trustedHosts.contains(challenge.protectionSpace.host) || task.checkAndConsumeTrust()) {
                print("Host is set as trusted!")
                completionHandler(NSURLSessionAuthChallengeDisposition.UseCredential, NSURLCredential(forTrust: challenge.protectionSpace.serverTrust!))
        } else {
            print("Host is not set as trusted, performing default handling...")
            completionHandler(NSURLSessionAuthChallengeDisposition.PerformDefaultHandling, nil)
        }
    }
}