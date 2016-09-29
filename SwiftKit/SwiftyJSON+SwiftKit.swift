//
//  SwiftyJSON+SwiftKit.swift
//  SwiftKit
//
//  Created by Aldrin Clemente on 28/09/2016.
//  Copyright © 2016 True Banana. All rights reserved.
//

import Foundation

extension JSON {
    
    public mutating func set(_ value: String) {
        self = JSON(value)
    }
    
    public mutating func set(_ value: Int) {
        self = JSON(value)
    }
    
    public mutating func set(_ value: Double) {
        self = JSON(value)
    }
    
    public mutating func set(_ value: Float) {
        self = JSON(value)
    }
    
    public mutating func set(_ value: Bool) {
        self = JSON(value)
    }
    
    public mutating func set(_ value: JSON) {
        self = value
    }
    
    public mutating func set(_ value: [JSON]) {
        self = JSON(value)
    }
    
    public mutating func set(_ value: [String : JSON]) {
        self = JSON(value)
    }
    
    public mutating func set(_ value: Any) {
        self = JSON(value)
    }
    
    public init() {
        self.init([:])
    }
}
