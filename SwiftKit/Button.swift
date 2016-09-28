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

@IBDesignable open class Button: UIButton {
    @IBInspectable open var defaultBackgroundColor: UIColor? {
        didSet {
            super.backgroundColor = defaultBackgroundColor
        }
    }
    @IBInspectable open var highlightedBackgroundColor: UIColor?
    @IBInspectable open var disabledBackgroundColor: UIColor?
    @IBInspectable open var borderColor: UIColor? {
        get {
            return UIColor(cgColor: layer.borderColor!)
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
    @IBInspectable open var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    @IBInspectable open var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
    
    override open var backgroundColor: UIColor? {
        get {
            return isEnabled ? (isHighlighted ? highlightedBackgroundColor : defaultBackgroundColor) : disabledBackgroundColor
        }
        set {
            super.backgroundColor = newValue
        }
    }
    
    override open var isHighlighted: Bool {
        didSet {
            refreshBackgroundColor()
        }
    }
    
    override open var isEnabled: Bool {
        didSet {
            refreshBackgroundColor()
        }
    }
    
    func refreshBackgroundColor() {
        backgroundColor = isEnabled ? (isHighlighted ? highlightedBackgroundColor : defaultBackgroundColor) : disabledBackgroundColor
    }
}
