# Swift Kit

Swift Kit is a collection of useful classes and methods to make some development tasks easier. This was originally my personal set of utilities which I've been using for a while now, and I've decided to share it with everyone in hopes that it will also save people some development time.

You may also be interested in [Android Kit](https://github.com/AldrinClemente/Android-Kit) if you're an Android developer.

----------

## Features

#### HTTP Kit
Makes HTTP requests simpler. Includes methods for parallel or serial (queued) asynchronous execution of requests with completion handlers. Provides ability to completely bypass SSL client authentication as needed. Requests with multi-part content body is also supported and has been made a lot simpler. All important details about the request and the response are also logged for easier debugging.

#### Crypto Kit
Includes a comprehensive set of utility methods for your cryptography needs. Supports cross-platform encryption/decryption of data (see [Android Kit](https://github.com/AldrinClemente/Android-Kit) for iOS) using the default crypto spec. You may also define your own spec to suits your needs (set the encryption algorithm, block cipher mode, padding, salt length, HMAC salt length, HMAC key length, key derivation iterations, PRF algorithm and MAC algorithm).

Encryption using a crypto spec implements secure random IV, password-based key derivation (PBKDF2) and keyed-hash message authentication code (HMAC). You may also use the different methods available to implement your own data format for encrypted data.

#### IAP Helper
Makes the implementation of in-app purchases even simpler.

#### GameKit Helper
Simplifies GameKit-related tasks such as submitting scores, showing leaderboards or managing cloud saved games.

#### Secure Data File
An encrypted data file you can use to persist app data without worrying about user tampering. Very useful for protecting game data against cheaters or hiding sensitive information from prying eyes.

#### Secure Variables
A set of classes which protect primitives from memory editors and similar cheating tools. Designed to combat game cheaters and enforce fair play on your games.

#### Async
A utility to make it easier to run tasks asynchronously with delay options and completion handlers.

#### Timer
A simple utility you can use for measuring elapsed time or benchmarking your code. Multiple timers can run at the same time.

#### Toast
Show Android-inspired toast messages in iOS with ease. Display duration, placement and colors are also configurable.

#### Activity Indicator
Introduces a very simple way to block the view and display an activity indicator at the same time without having to add or remove views on your own.

#### Extensions
Extensions for different classes for convenience. Includes UIColor initialization using hex RGB, NSData to hex string, convenient Base 64 encoding and decoding, dictionary to URL query parameters and more.

#### Views
Includes several extended views configurable in the interface builder, such as Label (UILabel) with configurable insets/padding. *Still deciding which ones to publish and which ones to remove.*

----------

## How to Use

### Manual Import

1. Clone **Swift Kit** ```$ git clone https://github.com/AldrinClemente/Swift-Kit.git```
2. Drag the **SwiftKit.xcodeproj** into the file navigator of your project to import it as a submodule
3. Select your project in the Project Navigator and select the application target under **Targets** in the sidebar then open the **General** tab
4. Click the **+** button under the **Embedded Binaries** section
5. Select **SwiftKit.framework** for the appropriate platform then click **Add**
6. Done! Just put ```import SwiftKit``` in your classes to use it. :D


### CocoaPods

*Coming soon!*

----------

## Notes

APIs/method names may still change a few times while we're still below 1.0. I'm still trying to decide on some class and method names and where to put them.

The HTTP Kit includes a modified JSON class from [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON) for handling JSON objects and arrays.

----------

## Bug Reports and Requests

Please submit bugs using the [issue tracker](https://github.com/AldrinClemente/Swift-Kit/issues/new). Feature requests are very welcome too!
