//
// Dictionary+SwiftKit.swift
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


public extension Dictionary {
    
    /// Build string representation of HTTP parameter dictionary of keys and objects
    // This percent escapes in compliance with RFC 3986
    // http://www.ietf.org/rfc/rfc3986.txt
    // :returns: String representation in the form of key1=value1&key2=value2 where the keys and values are percent escaped
    var stringFromQueryParameters: String {
        return arrayFromQueryParameters.joined(separator: "&")
    }
    
    var stringFromSortedQueryParameters: String {
        var parameters = arrayFromQueryParameters
        parameters.sort()
        return parameters.joined(separator: "&")
    }
    
    var arrayFromQueryParameters: [String] {
        return self.map { (arg) -> String in
            let (k, v) = arg
            let key = String(describing: k).stringByAddingPercentEncodingForURLQuery ?? "nil"
            let value = String(describing: v).stringByAddingPercentEncodingForURLQuery ?? "nil"
            return "\(key)=\(value)"
        }
    }
}
