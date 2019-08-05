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
    func encrypt(_ password: String) -> Data? {
        guard let encodedData = self.utf8EncodedData else {
            return nil
        }
        return Crypto.encrypt(data: encodedData, password: password)
    }
    
    func decrypt(_ password: String) -> Data? {
        guard let encodedData = self.utf8EncodedData else {
            return nil
        }
        return Crypto.decrypt(encryptedMessage: encodedData, password: password)
    }
    
    var base64EncodedData: Data? {
        return self.data(using: String.Encoding.utf8)?.base64DecodedData
    }
    
    var base64EncodedString: String? {
        if let data = base64EncodedData {
            return String(data: data, encoding: String.Encoding.utf8)
        } else {
            return nil
        }
    }
    
    var base64DecodedData: Data? {
        if let data = self.data(using: String.Encoding.utf8) {
            return Data(base64Encoded: data, options: .ignoreUnknownCharacters)
        } else {
            return nil
        }
    }
    
    var base64DecodedString: String? {
        if let data = base64DecodedData {
            return String(data: data, encoding: String.Encoding.utf8)
        } else {
            return nil
        }
    }
    
    var utf8EncodedData: Data? {
        return self.data(using: String.Encoding.utf8)
    }
    
    var sha1: String {
        return Crypto.SHA1(utf8EncodedData!)
    }
    
    var md5: String {
        return Crypto.MD5(utf8EncodedData!)
    }
    
    /// Percent escape value to be added to a URL query value as specified in RFC 3986
    // This percent-escapes all characters besize the alphanumeric character set and "-", ".", "_", and "~".
    // http://www.ietf.org/rfc/rfc3986.txt
    // :returns: Return precent escaped string.
    var stringByAddingPercentEncodingForURLQuery: String? {
        let characterSet = NSMutableCharacterSet.alphanumeric()
        characterSet.addCharacters(in: "-._~")
        return self.addingPercentEncoding(withAllowedCharacters: characterSet as CharacterSet)
    }
}
