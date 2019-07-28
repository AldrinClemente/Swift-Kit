//
// ToggleButton.swift
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

public protocol ToggleButtonDelegate {
    func toggleButton(_ toggleButton: ToggleButton, didBecomeActive: Bool)
}

@IBDesignable open class ToggleButton: Button {
    
    @IBInspectable open var activatedBackgroundColor: UIColor?
    
    @IBInspectable open var activated: Bool = false {
        didSet {
            refreshBackgroundColor()
        }
    }
    override open var backgroundColor: UIColor? {
        get {
            return activated ? activatedBackgroundColor : defaultBackgroundColor
        }
        set {
            super.backgroundColor = newValue
        }
    }
    
    override func refreshBackgroundColor() {
        backgroundColor = activated ? activatedBackgroundColor : defaultBackgroundColor
    }
    
    #if !TARGET_INTERFACE_BUILDER
    fileprivate var delegate: ToggleButtonDelegate?
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        delegate = self
        self.addTarget(self, action: #selector(ToggleButton.didReceiveTouchUpInside(_:)), for: .touchUpInside)
    }
    
    @objc func didReceiveTouchUpInside(_ sender: ToggleButton) {
        activated = !activated
        delegate?.toggleButton(self, didBecomeActive: activated)
    }
    #endif
}

extension ToggleButton: ToggleButtonDelegate {
    public func toggleButton(_ toggleButton: ToggleButton, didBecomeActive: Bool) {}
}
