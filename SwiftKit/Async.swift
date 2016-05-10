//
// Async.swift
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

public struct Async {
    public static func runOnBackgroundThread(task: Task, completion: Task? = nil) {
        runOnBackgroundThread(0, task: task, completion: completion)
    }
    
    public static func runOnBackgroundThread(delay: Double = 0.0, task: Task? = nil, completion: Task? = nil) {
        let backgroundTaskDelay = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
        dispatch_after(backgroundTaskDelay, dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
            task?()
            
            if completion != nil {
                let completionTaskDelay = dispatch_time(DISPATCH_TIME_NOW, 0)
                dispatch_after(completionTaskDelay, dispatch_get_main_queue()) {
                    completion?()
                }
            }
        }
    }
}

public typealias Task = () -> Void