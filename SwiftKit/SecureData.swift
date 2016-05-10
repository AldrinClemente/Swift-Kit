//
// SecureData.swift
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


public class SecureData {
    private var password: String?
    private var j: JSON
    
    public var json: JSON {
        return j
    }
    
    public var rawData: NSData {
        do {
            return try self.j.rawData()
        } catch {
            return NSData()
        }
    }
    
    public var data: NSData {
        let data = rawData
        if self.password != nil {
            return data.encrypt(self.password!) ?? data
        } else {
            return data
        }
    }
    
    public var string: String {
        return j.stringValue
    }
    
    public init(data: NSData = NSData(), password: String? = nil) {
        self.password = password
        self.j = SecureData.readData(data, password: password)
    }
    
    public func loadData(data: NSData, password: String? = nil) {
        self.j = SecureData.readData(data, password: password)
    }
    
    public static func readData(data: NSData, password: String? = nil) -> JSON {
        var d = data
        if password != nil && data.length > 0 {
            if let decryptedData = data.decrypt(password!) {
                d = decryptedData
            }
        }
        let json = JSON(data: d, options: .AllowFragments)
        return json.error == nil && json.type != .Null ? json : JSON()
    }
    
    public func put(key: String, value: String) {
        j[key].set(value)
    }
    
    public func put(key: String, value: Int) {
        print(j[key].int)
        print("setting value to \(value)")
        j[key].set(value)
        print(j[key].int)
    }
    
    public func put(key: String, value: Double) {
        j[key].set(value)
    }
    
    public func put(key: String, value: Float) {
        j[key].set(value)
    }
    
    public func put(key: String, value: Bool) {
        j[key].set(value)
    }
    
    public func put(key: String, value: JSON) {
        j[key].set(value)
    }
    
    public func put(key: String, value: [JSON]) {
        j[key].set(value)
    }
    
    public func put(key: String, value: [String : JSON]) {
        j[key].set(value)
    }
    
    public func put(key: String, value: [AnyObject]) {
        j[key].set(value)
        print(self.j)
    }
    
    public func put(key: String, value: [String : AnyObject]) {
        j[key].set(value)
    }
    
    public func getString(key: String) -> String? {
        return j[key].string
    }
    
    public func getInt(key: String) -> Int? {
        return j[key].int
    }
    
    public func getDouble(key: String) -> Double? {
        return j[key].double
    }
    
    public func getFloat(key: String) -> Float? {
        return j[key].float
    }
    
    public func getBool(key: String) -> Bool? {
        return j[key].bool
    }
    
    public func getJSON(key: String) -> JSON {
        let json = j[key]
        return json.type != .Null ? json : JSON()
    }
    
    public func getJSONArray(key: String) -> [JSON] {
        return j[key].arrayValue
    }
    
    public func getJSONDictionary(key: String) -> [String : JSON] {
        return j[key].dictionaryValue
    }
    
    public func getString(key: String, defaultValue: String) -> String {
        return j[key].string ?? defaultValue
    }
    
    public func getInt(key: String, defaultValue: Int) -> Int {
        return j[key].int ?? defaultValue
    }
    
    public func getDouble(key: String, defaultValue: Double) -> Double {
        return j[key].double ?? defaultValue
    }
    
    public func getFloat(key: String, defaultValue: Float) -> Float {
        return j[key].float ?? defaultValue
    }
    
    public func getBool(key: String, defaultValue: Bool) -> Bool {
        return j[key].bool ?? defaultValue
    }
    
    public func remove(key: String) {
        j[key] = nil
    }
    
    public func clear() {
        j.dictionaryObject?.removeAll()
    }
}

public class SecureDataFile: SecureData {
    private var fileURL: NSURL!
    
    public convenience init(fileName: String, password: String? = nil) {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let url = NSURL(fileURLWithPath: documentsPath).URLByAppendingPathComponent(fileName)
        
        self.init(fileURL: url, password: password)
    }
    
    public init(fileURL: NSURL, password: String? = nil) {
        self.fileURL = fileURL
        
        let data = NSData(contentsOfURL: fileURL) ?? NSData()
        super.init(data: data, password: password)
    }
    
    public static func getDefault() -> SecureDataFile {
        return SecureDataFile(fileName: "data")
    }
    
    public func saveAsync() {
        print("Saving data...")
        Async.runOnBackgroundThread(task: {
            let data = self.data
            if data.writeToURL(self.fileURL, atomically: true) {
                print("Saved data successfully with \(data.length) byte(s)")
            } else {
                print("Failed to write data")
            }
        })
    }
}
