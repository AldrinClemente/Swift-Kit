//
// NSData+SwiftKit.swift
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

public extension NSData {
    public func encrypt(password: String, spec: Crypto.Spec = Crypto.Spec()) -> NSData? {
        return Crypto.encrypt(self, password: password, spec: spec)
    }
    
    public func decrypt(password: String, spec: Crypto.Spec = Crypto.Spec()) -> NSData? {
        return Crypto.decrypt(self, password: password, spec: spec)
    }
    
    public var base64EncodedData: NSData {
        return self.base64EncodedDataWithOptions(.Encoding64CharacterLineLength)
    }
    
    public var base64EncodedString: String {
        return self.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
    }
    
    public var base64DecodedData: NSData? {
        return NSData(base64EncodedData: self, options: .IgnoreUnknownCharacters)
    }
    
    public var base64DecodedString: String? {
        return base64DecodedData != nil ? String(data: base64DecodedData!, encoding: NSUTF8StringEncoding) : nil
    }
    
    public var utf8EncodedString: String? {
        return String(data: self, encoding: NSUTF8StringEncoding)
    }
    
    public var hexString: String? {
        let buffer = UnsafePointer<UInt8>(self.bytes)
        if buffer == nil {
            return nil
        }
        
        var hexadecimalString = ""
        for i in 0..<self.length {
            hexadecimalString += String(format: "%02x", buffer.advancedBy(i).memory)
        }
        return hexadecimalString
    }
    
    public var sha1: String {
        return Crypto.SHA1(self)
    }
    
    public var md5: String {
        return Crypto.MD5(self)
    }
}


public extension NSMutableData {
    func appendString(string: String) {
        let data = string.dataUsingEncoding(NSUTF8StringEncoding)
        appendData(data!)
    }
}