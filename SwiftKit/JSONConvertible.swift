//  SwiftyJSON.swift
//
//  Copyright (c) 2014 Ruoyu Fu, Pinglin Tang
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation

// MARK: CustomStringConvertible, CustomDebugStringConvertible

extension JSON: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        if let string = self.rawString(options: .PrettyPrinted) {
            return string
        } else {
            return "nil"
        }
    }
    
    public var debugDescription: String {
        return description
    }
}

// MARK: LiteralConvertible

extension JSON: StringLiteralConvertible {
    public init(stringLiteral value: StringLiteralType) {
        self.init(value)
    }
    public init(extendedGraphemeClusterLiteral value: StringLiteralType) {
        self.init(value)
    }
    public init(unicodeScalarLiteral value: StringLiteralType) {
        self.init(value)
    }
}

extension JSON: IntegerLiteralConvertible {
    public init(integerLiteral value: IntegerLiteralType) {
        self.init(value)
    }
}

extension JSON: BooleanLiteralConvertible {
    public init(booleanLiteral value: BooleanLiteralType) {
        self.init(value)
    }
}

extension JSON: FloatLiteralConvertible {
    public init(floatLiteral value: FloatLiteralType) {
        self.init(value)
    }
}

extension JSON: DictionaryLiteralConvertible {
    public init(dictionaryLiteral elements: (String, AnyObject)...) {
        self.init(elements.reduce([String : AnyObject]()){
            (dictionary: [String : AnyObject], element:(String, AnyObject)) -> [String : AnyObject] in
            var d = dictionary
            d[element.0] = element.1
            return d
            }
        )
    }
}

extension JSON: ArrayLiteralConvertible {
    public init(arrayLiteral elements: AnyObject...) {
        self.init(elements)
    }
}

extension JSON: NilLiteralConvertible {
    public init(nilLiteral: ()) {
        self.init(NSNull())
    }
}

// MARK: Raw

extension JSON: RawRepresentable {
    
    public init?(rawValue: AnyObject) {
        if JSON(rawValue).type == .Unknown {
            return nil
        } else {
            self.init(rawValue)
        }
    }
    
    public var rawValue: AnyObject {
        return self.object
    }
    
    public func rawData(options opt: NSJSONWritingOptions = NSJSONWritingOptions(rawValue: 0)) throws -> NSData {
        if NSJSONSerialization.isValidJSONObject(self.object) {
            return try NSJSONSerialization.dataWithJSONObject(self.object, options: opt)
        } else {
            throw NSError(domain: ErrorDomain, code: JSONError.InvalidJSON.rawValue, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON data"])
        }
    }
    
    public func rawString(encoding: UInt = NSUTF8StringEncoding, options opt: NSJSONWritingOptions = .PrettyPrinted) -> String? {
        switch self.type {
        case .Array, .Dictionary:
            do {
                let data = try self.rawData(options: opt)
                return NSString(data: data, encoding: encoding) as? String
            } catch _ {
                return nil
            }
        case .String:
            return self.rawString
        case .Number:
            return self.rawNumber.stringValue
        case .Bool:
            return self.rawNumber.boolValue.description
        case .Null:
            return "null"
        default:
            return nil
        }
    }
}