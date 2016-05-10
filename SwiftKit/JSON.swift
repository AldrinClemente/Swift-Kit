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

// MARK: JSON Base

public struct JSON {
    
    public init(data: NSData, options: NSJSONReadingOptions = .AllowFragments, error: NSErrorPointer = nil) {
        do {
            let object: AnyObject = try NSJSONSerialization.JSONObjectWithData(data, options: options)
            self.init(object)
        } catch let e as NSError {
            if error != nil {
                error.memory = e
            }
            self.init(NSNull())
        }
    }
    
    public init() {
        self.init([:])
    }
    
    public static func parse(string: String) -> JSON {
        return string.dataUsingEncoding(NSUTF8StringEncoding)
            .flatMap({
                data in
                JSON(data: data)
            }) ?? JSON(NSNull())
    }
    
    /**
     Creates a JSON from an object.
     
     - parameter object:  The object must have the following properties: All objects are NSString/String, NSNumber/Int/Float/Double/Bool, NSArray/Array, NSDictionary/Dictionary, or NSNull; All dictionary keys are NSStrings/String; NSNumbers are not NaN or infinity.
     - returns: The created JSON
     */
    public init(_ object: AnyObject) {
        self.object = object
    }
    
    public init(_ jsonArray: [JSON]) {
        self.init(jsonArray.map { $0.object })
    }
    
    public init(_ jsonDictionary: [String : JSON]) {
        var dictionary: [String: AnyObject] = [:]
        for (key, json) in jsonDictionary {
            dictionary[key] = json.object
        }
        self.init(dictionary)
    }
    
    var rawArray: [AnyObject] = []
    var rawDictionary: [String : AnyObject] = [:]
    var rawString: String = ""
    var rawNumber: NSNumber = 0
    var rawNull: NSNull = NSNull()
    var _type: Type = .Null
    var _error: NSError? = nil
    
    public var type: Type { get { return _type } }
    public var error: NSError? { get { return self._error } }
    
    public static var null: JSON { get { return JSON(NSNull()) } }
    
    /// Object in JSON
    public var object: AnyObject {
        get {
            switch self.type {
            case .Array:
                return self.rawArray
            case .Dictionary:
                return self.rawDictionary
            case .String:
                return self.rawString
            case .Number:
                return self.rawNumber
            case .Bool:
                return self.rawNumber
            default:
                return self.rawNull
            }
        }
        set {
            _error = nil
            switch newValue {
            case let number as NSNumber:
                if number.isBool {
                    _type = .Bool
                } else {
                    _type = .Number
                }
                self.rawNumber = number
            case  let string as String:
                _type = .String
                self.rawString = string
            case  _ as NSNull:
                _type = .Null
            case let array as [AnyObject]:
                _type = .Array
                self.rawArray = array
            case let dictionary as [String : AnyObject]:
                _type = .Dictionary
                self.rawDictionary = dictionary
            default:
                _type = .Unknown
                _error = NSError(domain: ErrorDomain, code: JSONError.UnsupportedType.rawValue, userInfo: [NSLocalizedDescriptionKey: "Unsupported object type"])
            }
        }
    }
}

// MARK: Convenience Setters

extension JSON {
    
    public mutating func set(value: String) {
        self = JSON(value)
    }
    
    public mutating func set(value: Int) {
        self = JSON(value)
    }
    
    public mutating func set(value: Double) {
        self = JSON(value)
    }
    
    public mutating func set(value: Float) {
        self = JSON(value)
    }
    
    public mutating func set(value: Bool) {
        self = JSON(value)
    }
    
    public mutating func set(value: JSON) {
        self = value
    }
    
    public mutating func set(value: [JSON]) {
        self = JSON(value)
    }
    
    public mutating func set(value: [String : JSON]) {
        self = JSON(value)
    }
    
    public mutating func set(value: AnyObject) {
        self = JSON(value)
    }
}

// MARK: Array

extension JSON {
    
    public var array: [JSON]? {
        get {
            if self.type == .Array {
                return self.rawArray.map{ JSON($0) }
            } else {
                return nil
            }
        }
    }
    
    public var arrayValue: [JSON] {
        get {
            return self.array ?? []
        }
    }
    
    public var arrayObject: [AnyObject]? {
        get {
            switch self.type {
            case .Array:
                return self.rawArray
            default:
                return nil
            }
        }
        set {
            if let array = newValue {
                self.object = array
            } else {
                self.object = NSNull()
            }
        }
    }
}

// MARK: Dictionary

extension JSON {
    
    public var dictionary: [String : JSON]? {
        if self.type == .Dictionary {
            return self.rawDictionary.reduce([String : JSON]()) { (dictionary: [String : JSON], element: (String, AnyObject)) -> [String : JSON] in
                var d = dictionary
                d[element.0] = JSON(element.1)
                return d
            }
        } else {
            return nil
        }
    }
    
    public var dictionaryValue: [String: JSON] {
        get {
            return self.dictionary ?? [:]
        }
    }
    
    public var dictionaryObject: [String : AnyObject]? {
        get {
            switch self.type {
            case .Dictionary:
                return self.rawDictionary
            default:
                return nil
            }
        }
        set {
            if let v = newValue {
                self.object = v
            } else {
                self.object = NSNull()
            }
        }
    }
}

// MARK: Bool

extension JSON {
    //Optional bool
    public var bool: Bool? {
        get {
            switch self.type {
            case .Bool:
                return self.rawNumber.boolValue
            default:
                return nil
            }
        }
        set {
            if let newValue = newValue {
                self.object = NSNumber(bool: newValue)
            } else {
                self.object = NSNull()
            }
        }
    }
    
    public var boolValue: Bool {
        return self.bool ?? false
    }
}

// MARK: String

extension JSON {
    //Optional string
    public var string: String? {
        get {
            switch self.type {
            case .String:
                return self.object as? String
            default:
                return nil
            }
        }
        set {
            if let newValue = newValue {
                self.object = NSString(string:newValue)
            } else {
                self.object = NSNull()
            }
        }
    }
    
    public var stringValue: String {
        get {
            switch self.type {
            case .String:
                return self.object as? String ?? ""
            case .Number:
                return self.object.stringValue
            case .Bool:
                return (self.object as? Bool).map { value in String(value) } ?? ""
            default:
                return ""
            }
        }
    }
}

// MARK: Int, Double, Float

extension JSON {
    
    public var double: Double? {
        get {
            return self.number?.doubleValue
        }
        set {
            if let newValue = newValue {
                self.object = NSNumber(double: newValue)
            } else {
                self.object = NSNull()
            }
        }
    }
    
    public var doubleValue: Double {
        get {
            return self.double ?? Double(0)
        }
    }
    
    public var float: Float? {
        get {
            return self.number?.floatValue
        }
        set {
            if let newValue = newValue {
                self.object = NSNumber(float: newValue)
            } else {
                self.object = NSNull()
            }
        }
    }
    
    public var floatValue: Float {
        get {
            return self.float ?? Float(0)
        }
    }
    
    public var int: Int? {
        get {
            return self.number?.longValue
        }
        set {
            if let newValue = newValue {
                self.object = NSNumber(integer: newValue)
            } else {
                self.object = NSNull()
            }
        }
    }
    
    public var intValue: Int {
        get {
            return self.int ?? 0
        }
    }
}

// MARK: Number

extension JSON {
    //Optional number
    public var number: NSNumber? {
        get {
            switch self.type {
            case .Number, .Bool:
                return self.rawNumber
            default:
                return nil
            }
        }
        set {
            self.object = newValue ?? NSNull()
        }
    }
    
    //Non-optional number
    public var numberValue: NSNumber {
        get {
            switch self.type {
            case .String:
                let decimal = NSDecimalNumber(string: self.object as? String)
                if decimal == NSDecimalNumber.notANumber() {  // indicates parse error
                    return NSDecimalNumber.zero()
                }
                return decimal
            case .Number, .Bool:
                return self.object as? NSNumber ?? NSNumber(int: 0)
            default:
                return NSNumber(double: 0.0)
            }
        }
        set {
            self.object = newValue
        }
    }
}

// MARK: Null

extension JSON {
    public var null: NSNull? {
        get {
            switch self.type {
            case .Null:
                return self.rawNull
            default:
                return nil
            }
        }
        set {
            self.object = NSNull()
        }
    }
    
    public var exists: Bool {
        if let e = error where e.code == JSONError.NonExistentKey.rawValue {
            return false
        }
        return true
    }
}

// MARK: URL

extension JSON {
    //Optional URL
    public var URL: NSURL? {
        get {
            switch self.type {
            case .String:
                if let encodedString = self.rawString.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet()) {
                    return NSURL(string: encodedString)
                } else {
                    return nil
                }
            default:
                return nil
            }
        }
        set {
            self.object = newValue?.absoluteString ?? NSNull()
        }
    }
}

// MARK: NSNumber

private let trueNumber = NSNumber(bool: true)
private let falseNumber = NSNumber(bool: false)
private let trueObjCType = String.fromCString(trueNumber.objCType)
private let falseObjCType = String.fromCString(falseNumber.objCType)

extension NSNumber {
    var isBool: Bool {
        get {
            let objCType = String.fromCString(self.objCType)
            if (self.compare(trueNumber) == NSComparisonResult.OrderedSame && objCType == trueObjCType)
                || (self.compare(falseNumber) == NSComparisonResult.OrderedSame && objCType == falseObjCType){
                    return true
            } else {
                return false
            }
        }
    }
}

public enum Type: Int {
    case Number
    case String
    case Bool
    case Array
    case Dictionary
    case Null
    case Unknown
}