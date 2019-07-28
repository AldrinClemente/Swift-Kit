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

public extension Data {
    func encrypt(_ password: String, spec: Crypto.Spec? = Crypto.Spec()) -> Data? {
        guard let spc = spec else {
            return nil
        }
        return Crypto.encrypt(data: self, password: password, spec: spc)
    }
    
    func decrypt(_ password: String, spec: Crypto.Spec? = Crypto.Spec()) -> Data? {
        guard let spc = spec else {
            return nil
        }
        return Crypto.decrypt(encryptedMessage: self, password: password, spec: spc)
    }
    
    var base64EncodedData: Data {
        return self.base64EncodedData(options: .lineLength64Characters)
    }
    
    var base64EncodedString: String {
        return self.base64EncodedString(options: .lineLength64Characters)
    }
    
    var base64DecodedData: Data? {
        return Data(base64Encoded: self, options: .ignoreUnknownCharacters)
    }
    
    var base64DecodedString: String? {
        guard let decodedData = base64DecodedData else {
            return nil
        }
        return String(data: decodedData, encoding: String.Encoding.utf8)
    }
    
    var utf8EncodedString: String? {
        return String(data: self, encoding: String.Encoding.utf8)
    }
    
    var hexString: String? {
        let buffer = (self as NSData).bytes.bindMemory(to: UInt8.self, capacity: self.count)
        
        var hexadecimalString = ""
        for i in 0..<self.count {
            hexadecimalString += String(format: "%02x", buffer.advanced(by: i).pointee)
        }
        return hexadecimalString
    }
    
    var sha1: String {
        return Crypto.SHA1(self)
    }
    
    var md5: String {
        return Crypto.MD5(self)
    }
}

public extension Data {
    mutating func appendString(_ string: String) {
        if let data = string.data(using: String.Encoding.utf8) {
            append(data)
        }
    }
}
