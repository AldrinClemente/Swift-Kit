//
// Button.swift
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
import UIKit

@IBDesignable public class Button: UIButton {
    @IBInspectable public var defaultBackgroundColor: UIColor? {
        didSet {
            super.backgroundColor = defaultBackgroundColor
        }
    }
    @IBInspectable public var highlightedBackgroundColor: UIColor?
    @IBInspectable public var disabledBackgroundColor: UIColor?
    @IBInspectable public var borderColor: UIColor? {
        get {
            return UIColor(CGColor: layer.borderColor!)
        }
        set {
            layer.borderColor = newValue?.CGColor
        }
    }
    @IBInspectable public var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    @IBInspectable public var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
    
    override public var backgroundColor: UIColor? {
        get {
            return enabled ? (highlighted ? highlightedBackgroundColor : defaultBackgroundColor) : disabledBackgroundColor
        }
        set {
            super.backgroundColor = newValue
        }
    }
    
    override public var highlighted: Bool {
        didSet {
            refreshBackgroundColor()
        }
    }
    
    override public var enabled: Bool {
        didSet {
            refreshBackgroundColor()
        }
    }
    
    func refreshBackgroundColor() {
        backgroundColor = enabled ? (highlighted ? highlightedBackgroundColor : defaultBackgroundColor) : disabledBackgroundColor
    }
}