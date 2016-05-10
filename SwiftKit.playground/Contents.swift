//: Playground - noun: a place where people can play

import UIKit
import SwiftKit


var x = SecureInt(value: 1)
var y = 0;
Timer.start()
for i in 0...3000000 {
    x.value += 1
}

print(Timer.stop() * 1000000000)