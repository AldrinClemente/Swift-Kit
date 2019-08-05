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


open class SecureData {
    fileprivate static var defaultSpec: Crypto.Spec = Crypto.Spec().setKeyDerivationIterations(128)
    
    fileprivate var password: String?
    fileprivate var j: JSON
    
    open var json: JSON {
        return j
    }
    
    open var rawData: Data {
        do {
            return try self.j.rawData()
        } catch {
            return Data()
        }
    }
    
    open var data: Data {
        let data = rawData
        if self.password != nil {
            return data.encrypt(self.password!, spec: SecureData.defaultSpec) ?? data
        } else {
            return data
        }
    }
    
    open var string: String {
        return j.stringValue
    }
    
    public init(data: Data = Data(), password: String? = nil) {
        self.password = password
        self.j = SecureData.readData(data, password: password)
    }
    
    open func loadData(_ data: Data, password: String? = nil) {
        self.j = SecureData.readData(data, password: password)
    }
    
    public static func readData(_ data: Data, password: String? = nil) -> JSON {
        var d = data
        if password != nil && data.count > 0 {
            if let decryptedData = data.decrypt(password!, spec: defaultSpec) {
                d = decryptedData
            }
        }
        let json = JSON(data: d, options: .allowFragments)
        return json.error == nil && json.type != .null ? json : JSON()
    }
    
    open func put(_ key: String, value: String) {
        j[key].set(value)
    }
    
    open func put(_ key: String, value: Int) {
        j[key].set(value)
    }
    
    open func put(_ key: String, value: Double) {
        j[key].set(value)
    }
    
    open func put(_ key: String, value: Float) {
        j[key].set(value)
    }
    
    open func put(_ key: String, value: Bool) {
        j[key].set(value)
    }
    
    open func put(_ key: String, value: JSON) {
        j[key].set(value)
    }
    
    open func put(_ key: String, value: [JSON]) {
        j[key].set(value)
    }
    
    open func put(_ key: String, value: [String : JSON]) {
        j[key].set(value)
    }
    
    open func put(_ key: String, value: [AnyObject]) {
        j[key].set(value)
        print(self.j)
    }
    
    open func put(_ key: String, value: [String : AnyObject]) {
        j[key].set(value)
    }
    
    open func getString(_ key: String) -> String? {
        return j[key].string
    }
    
    open func getInt(_ key: String) -> Int? {
        return j[key].int
    }
    
    open func getDouble(_ key: String) -> Double? {
        return j[key].double
    }
    
    open func getFloat(_ key: String) -> Float? {
        return j[key].float
    }
    
    open func getBool(_ key: String) -> Bool? {
        return j[key].bool
    }
    
    open func getJSON(_ key: String) -> JSON {
        let json = j[key]
        return json.type != .null ? json : JSON()
    }
    
    open func getJSONArray(_ key: String) -> [JSON] {
        return j[key].arrayValue
    }
    
    open func getJSONDictionary(_ key: String) -> [String : JSON] {
        return j[key].dictionaryValue
    }
    
    open func getString(_ key: String, defaultValue: String) -> String {
        return j[key].string ?? defaultValue
    }
    
    open func getInt(_ key: String, defaultValue: Int) -> Int {
        return j[key].int ?? defaultValue
    }
    
    open func getDouble(_ key: String, defaultValue: Double) -> Double {
        return j[key].double ?? defaultValue
    }
    
    open func getFloat(_ key: String, defaultValue: Float) -> Float {
        return j[key].float ?? defaultValue
    }
    
    open func getBool(_ key: String, defaultValue: Bool) -> Bool {
        return j[key].bool ?? defaultValue
    }
    
    open func remove(_ key: String) {
        j[key] = nil
    }
    
    open func clear() {
        j.dictionaryObject?.removeAll()
    }
}

open class SecureDataFile: SecureData {
    fileprivate var fileURL: URL!
    
    public convenience init(fileName: String, password: String? = nil) {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let url = URL(fileURLWithPath: documentsPath).appendingPathComponent(fileName)
        
        self.init(fileURL: url, password: password)
    }
    
    public init(fileURL: URL, password: String? = nil) {
        self.fileURL = fileURL
        
        let data = (try? Data(contentsOf: fileURL)) ?? Data()
        super.init(data: data, password: password)
    }
    
    public static func getDefault() -> SecureDataFile {
        return SecureDataFile(fileName: "data")
    }
    
    open func saveAsync() {
        print("Saving data...")
        Async.runOnBackgroundThread(task: {
            let data = self.data
            if (try? data.write(to: self.fileURL, options: [.atomic])) != nil {
                print("Saved data successfully with \(data.count) byte(s)")
            } else {
                print("Failed to write data")
            }
        })
    }
}
