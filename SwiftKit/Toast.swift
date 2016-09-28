//
// Toast.swift
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

public struct Toast {
    
    public static var verticalOffset: CGFloat = 0.8
    public static var textColor: UIColor = UIColor.white
    public static var backgroundColor: UIColor = UIColor(hex: 0x000000, alpha: 0xCC)
    
    class Toast {
        static var text: UILabel = UILabel()
    }
    
    public static func show(_ text: String,
                            duration: TimeInterval = 2.5,
                            textColor: UIColor = textColor,
                            backgroundColor: UIColor = backgroundColor,
                            verticalOffset: CGFloat = verticalOffset,
                            parentView: UIView? = nil) {
        var view: UIView
        if parentView != nil {
            view = parentView!
        } else if let rootView = UIApplication.shared.keyWindow?.subviews.last {
            view = rootView
        } else {
            return
        }
        
        // We're doing this to ensure that we the toast will be a child of the top-most view, whatever it is
        while view.superview != nil {
            view = view.superview!
        }
        
        if Toast.text.text == nil {
            Toast.text.textAlignment = NSTextAlignment.center
            Toast.text.numberOfLines = 8
            Toast.text.font = UIFont(name: Toast.text.font.fontName, size: 14)
            Toast.text.layer.cornerRadius = 8
            Toast.text.clipsToBounds = true
        }
        
        
        Toast.text.removeFromSuperview()
        view.addSubview(Toast.text)
        
        Toast.text.frame = CGRect(x: 0, y: 0, width: view.frame.width - 64, height: view.frame.height)
        
        Toast.text.backgroundColor = backgroundColor
        Toast.text.textColor = textColor
        
        Toast.text.alpha = 1
        Toast.text.text = text
        Toast.text.sizeToFit()
        var textSize = Toast.text.bounds.size
        textSize.width += 16
        textSize.height += 16
        Toast.text.bounds.size = textSize
        
        var center = view.center
        center.y = center.y * verticalOffset * 2
        Toast.text.center = center
        
        
        UIView.animate(withDuration: 0.5,
            delay: duration - 0.5,
            options: UIViewAnimationOptions.beginFromCurrentState,
            animations: {
                Toast.text.alpha = 0
            },
            completion: { finished in
                if finished {
                    Toast.text.removeFromSuperview()
                    Toast.text.alpha = 1
                }
        })
    }
}

extension UIViewController {
    public func showToast(_ text: String, duration: TimeInterval = 2.5, verticalOffset: CGFloat = 0.8) {
        Toast.show(text, duration: duration, verticalOffset: verticalOffset, parentView: view)
    }
}
