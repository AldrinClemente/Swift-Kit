//
// Response.swift
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


open class Response {
    public var rawError: URLError?
    var _data: Data?
    var httpResponse: HTTPURLResponse?
    public var originalRequest: Request?
    public var string: String? {
        return _data != nil ? String(data: _data!, encoding: String.Encoding.utf8) : nil
    }
    public var json: JSON? {
        return _data != nil ? JSON(data: _data!, options: .allowFragments) : nil
    }
    public var data: Data? {
        return _data
    }
    public var statusCode: Int? {
        return httpResponse?.statusCode
    }
    public var statusDescription: String? {
        return statusCode != nil ? HTTPURLResponse.localizedString(forStatusCode: statusCode!).capitalized : nil
    }
    public var statusMessage: String? {
        return statusCode != nil ? "\(statusCode!) \(statusDescription!)" : nil
    }
    public var headers: [AnyHashable: Any] {
        return httpResponse?.allHeaderFields ?? [:]
    }
    public var isInformational: Bool {
        return statusCode >= 100 && statusCode < 200
    }
    public var isSuccess: Bool {
        return statusCode >= 200 && statusCode < 300
    }
    public var isRedirection: Bool {
        return statusCode >= 300 && statusCode < 400
    }
    public var isClientError: Bool {
        return statusCode >= 400 && statusCode < 500
    }
    public var isServerError: Bool {
        return statusCode >= 500 && statusCode < 600
    }
    public var error: RequestError? {
        if let e = rawError?.errorCode {
            switch e {
            case NSURLErrorTimedOut:
                return RequestError.timeout
            case NSURLErrorServerCertificateHasBadDate,
            NSURLErrorServerCertificateUntrusted,
            NSURLErrorServerCertificateHasUnknownRoot,
            NSURLErrorServerCertificateNotYetValid:
                return RequestError.serverAuthenticationFailed
            case NSURLErrorClientCertificateRejected,
            NSURLErrorClientCertificateRequired:
                return RequestError.clientAuthenticationFailed
            case NSURLErrorNotConnectedToInternet:
                return RequestError.noNetworkConnection
            default:
                if #available(iOS 9.0, *) {
                    if e == NSURLErrorAppTransportSecurityRequiresSecureConnection {
                        return RequestError.appTransportSecurity
                    } else {
                        return RequestError.other(error: rawError!)
                    }
                } else {
                    return RequestError.other(error: rawError!)
                }
            }
        } else {
            return nil
        }
    }
    
    init(originalRequest: Request?, data: Data?, httpResponse: HTTPURLResponse?, error: Error?) {
        self.originalRequest = originalRequest
        if error == nil {
            self._data = data
            self.httpResponse = httpResponse
        } else {
            rawError = error as? URLError
        }
    }
}

extension Response: CustomStringConvertible {
    public var description: String {
        return self.string ?? "nil"
    }
}
