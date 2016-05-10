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

public enum JSONKey {
    case Index(Int)
    case Key(String)
}

public protocol JSONSubscript {
    var jsonKey: JSONKey { get }
}

extension Int: JSONSubscript {
    public var jsonKey: JSONKey {
        return JSONKey.Index(self)
    }
}

extension String: JSONSubscript {
    public var jsonKey: JSONKey {
        return JSONKey.Key(self)
    }
}

extension JSON {
    
    private subscript(index index: Int) -> JSON {
        get {
            if self.type != .Array {
                var r = JSON.null
                r._error = self._error ?? NSError(domain: ErrorDomain, code: JSONError.NotAJSONArray.rawValue, userInfo: [NSLocalizedDescriptionKey: "Index \(index) not found: Not a JSON array"])
                return r
            } else if index >= 0 && index < self.rawArray.count {
                return JSON(self.rawArray[index])
            } else {
                var r = JSON.null
                r._error = NSError(domain: ErrorDomain, code: JSONError.IndexOutOfBounds.rawValue, userInfo: [NSLocalizedDescriptionKey: "Array index \(index) out of bounds, size is \(self.rawArray.count)"])
                return r
            }
        }
        set {
            if self.type == .Array {
                if self.rawArray.count > index && newValue.error == nil {
                    self.rawArray[index] = newValue.object
                }
            }
        }
    }
    
    private subscript(key key: String) -> JSON {
        get {
            var r = JSON.null
            if self.type == .Dictionary {
                if let o = self.rawDictionary[key] {
                    r = JSON(o)
                } else {
                    r._error = NSError(domain: ErrorDomain, code: JSONError.NonExistentKey.rawValue, userInfo: [NSLocalizedDescriptionKey: "Key \(key) does not exist"])
                }
            } else {
                r._error = self._error ?? NSError(domain: ErrorDomain, code: JSONError.NotAJSONObject.rawValue, userInfo: [NSLocalizedDescriptionKey: "Key \(key) not found: Not a JSON object"])
            }
            return r
        }
        set {
            if self.type == .Dictionary && newValue.error == nil {
                self.rawDictionary[key] = newValue.object
            }
        }
    }
    
    private subscript(sub sub: JSONSubscript) -> JSON {
        get {
            switch sub.jsonKey {
            case .Index(let index): return self[index: index]
            case .Key(let key): return self[key: key]
            }
        }
        set {
            switch sub.jsonKey {
            case .Index(let index): self[index: index] = newValue
            case .Key(let key): self[key: key] = newValue
            }
        }
    }
    
    public subscript(path: [JSONSubscript]) -> JSON {
        get {
            return path.reduce(self) { $0[sub: $1] }
        }
        set {
            switch path.count {
            case 0:
                return
            case 1:
                self[sub:path[0]].object = newValue.object
            default:
                var aPath = path; aPath.removeAtIndex(0)
                var nextJSON = self[sub: path[0]]
                nextJSON[aPath] = newValue
                self[sub: path[0]] = nextJSON
            }
        }
    }
    
    public subscript(path: JSONSubscript...) -> JSON {
        get {
            return self[path]
        }
        set {
            self[path] = newValue
        }
    }
}