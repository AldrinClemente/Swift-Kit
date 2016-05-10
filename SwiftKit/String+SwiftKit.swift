//
// String+SwiftKit.swift
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

public extension String {
    public func encrypt(password: String) -> NSData? {
        return Crypto.encrypt(self.utf8EncodedData!, password: password)
    }
    
    public func decrypt(password: String) -> NSData? {
        return Crypto.decrypt(self.utf8EncodedData!, password: password)
    }
    
    public var base64EncodedData: NSData? {
        return self.dataUsingEncoding(NSUTF8StringEncoding)?.base64DecodedData
    }
    
    public var base64EncodedString: String? {
        if let data = base64EncodedData {
            return String(data: data, encoding: NSUTF8StringEncoding)
        } else {
            return nil
        }
    }
    
    public var base64DecodedData: NSData? {
        if let data = self.dataUsingEncoding(NSUTF8StringEncoding) {
            return NSData(base64EncodedData: data, options: .IgnoreUnknownCharacters)
        } else {
            return nil
        }
    }
    
    public var base64DecodedString: String? {
        if let data = base64DecodedData {
            return String(data: data, encoding: NSUTF8StringEncoding)
        } else {
            return nil
        }
    }
    
    public var utf8EncodedData: NSData? {
        return self.dataUsingEncoding(NSUTF8StringEncoding)
    }
    
    /// Percent escape value to be added to a URL query value as specified in RFC 3986
    // This percent-escapes all characters besize the alphanumeric character set and "-", ".", "_", and "~".
    // http://www.ietf.org/rfc/rfc3986.txt
    // :returns: Return precent escaped string.
    public var stringByAddingPercentEncodingForURLQuery: String? {
        let characterSet = NSMutableCharacterSet.alphanumericCharacterSet()
        characterSet.addCharactersInString("-._~")
        return self.stringByAddingPercentEncodingWithAllowedCharacters(characterSet)
    }
}