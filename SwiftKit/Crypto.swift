//
// Crypto.swift
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
import CommonCrypto

public struct Crypto {
    
    open class Spec {
        public init() {
        }
        
        public var algorithm = EncryptionAlgorithm.AES256
        public var blockCipherMode = BlockCipherMode.CBC
        public var padding = Padding.PKCS7
        public var saltLength = 16
        public var hmacSaltLength = 16
        public var hmacKeyLength = 16
        public var keyDerivationIterations = 10000
        public var prfAlgorithm = PRFAlgorithm.HMACSHA1 // Use HMACSHA1 to ensure data cross-compatibility with Android
        public var macAlgorithm = MACAlgorithm.HMACSHA256
        
        open func setAlgorithm(_ algorithm: EncryptionAlgorithm) -> Spec {
            self.algorithm = algorithm
            return self
        }
        
        open func setBlockCipherMode(_ mode: BlockCipherMode) -> Spec {
            self.blockCipherMode = mode
            return self
        }
        
        open func setPadding(_ padding: Padding) -> Spec {
            self.padding = padding
            return self
        }
        
        open func setSaltLength(_ length: Int) -> Spec {
            self.saltLength = length
            return self
        }
        
        open func setHMACSaltLength(_ length: Int) -> Spec {
            self.hmacSaltLength = length
            return self
        }
        
        open func setHMACKeyLength(_ length: Int) -> Spec {
            self.hmacKeyLength = length
            return self
        }
        
        open func setKeyDerivationIterations(_ iterations: Int) -> Spec {
            self.keyDerivationIterations = iterations
            return self
        }
        
        open func setPRFAlgorithm(_ algorithm: PRFAlgorithm) -> Spec {
            self.prfAlgorithm = algorithm
            return self
        }
        
        open func setMACAlgorithm(_ algorithm: MACAlgorithm) -> Spec {
            self.macAlgorithm = algorithm
            return self
        }
    }
    
    public static func encrypt(data: Data, password: String, spec: Spec = Spec()) -> Data? {
        guard let salt = generateSecureRandomData(length: spec.saltLength) else {
            return nil
        }
        guard let key = PBKDF2(password: password, salt: salt, iterations: spec.keyDerivationIterations, length: spec.algorithm.minKeySize, algorithm: spec.prfAlgorithm) else {
            return nil
        }
        guard let iv = generateSecureRandomData(length: spec.algorithm.blockSize) else {
            return nil
        }
        guard let encryptedData = encrypt(data: data, key: key, iv: iv, algorithm: spec.algorithm, blockCipherMode: spec.blockCipherMode, padding: spec.padding) else {
            return nil
        }
        guard let hmacSalt = generateSecureRandomData(length: spec.hmacSaltLength) else {
            return nil
        }
        guard let hmacKey = PBKDF2(password: password, salt: hmacSalt, iterations: spec.keyDerivationIterations, length: spec.hmacKeyLength, algorithm: spec.prfAlgorithm) else {
            return nil
        }
        guard let hmac = HMAC(key: hmacKey, message: encryptedData, algorithm: spec.macAlgorithm) else {
            return nil
        }
        
        // TODO: Consider adding versioning in case of change in format later
        var message = Data()
        message.append(salt)
        message.append(hmacSalt)
        message.append(iv)
        message.append(encryptedData)
        message.append(hmac)
        
        return message
    }
    
    public static func decrypt(encryptedMessage: Data, password: String, spec: Spec = Spec()) -> Data? {
        let data = Data(encryptedMessage)
        
        let ivLength = spec.algorithm.blockSize
        let hmacLength = spec.macAlgorithm.macLength
        let encryptedDataLength = encryptedMessage.count - spec.saltLength - spec.hmacSaltLength - ivLength - hmacLength
        
        let saltLocation = 0
        let hmacSaltLocation = saltLocation + spec.saltLength
        let ivLocation = hmacSaltLocation + spec.hmacSaltLength
        let encryptedDataLocation = ivLocation + ivLength
        let hmacLocation = encryptedDataLocation + encryptedDataLength
        
        guard encryptedDataLength > 0 && hmacLocation + hmacLength == encryptedMessage.count else {
            return nil
        }
        
        let salt = data.subdata(in: saltLocation..<saltLocation + spec.saltLength)
        let hmacSalt = data.subdata(in: hmacSaltLocation..<hmacSaltLocation + spec.hmacSaltLength)
        let iv = data.subdata(in: ivLocation..<ivLocation + ivLength)
        
        let hmac = data.subdata(in: hmacLocation..<hmacLocation + hmacLength)
        
        let encryptedData = data.subdata(in: encryptedDataLocation..<encryptedDataLocation + encryptedDataLength)
        
        let hmacKey = PBKDF2(password: password, salt: hmacSalt, iterations: spec.keyDerivationIterations, length: spec.hmacKeyLength, algorithm: spec.prfAlgorithm)!
        
        guard HMAC(key: hmacKey, message: encryptedData, algorithm: spec.macAlgorithm) == hmac else {
            return nil
        }
        
        let key = PBKDF2(password: password, salt: salt, iterations: spec.keyDerivationIterations, length: spec.algorithm.minKeySize, algorithm: spec.prfAlgorithm)!
        
        return decrypt(data: encryptedData, key: key, iv: iv, algorithm: spec.algorithm, blockCipherMode: spec.blockCipherMode, padding: spec.padding)
    }
    
    
    
    // Encryption / Decryption
    // ********************************************************************************
    
    public static func encrypt(data: Data, key: Data, iv: Data? = nil, algorithm: EncryptionAlgorithm, blockCipherMode: BlockCipherMode = .CBC, padding: Padding = .PKCS7) -> Data? {
        return crypt(data: data, key: key, iv: iv, algorithm: algorithm, blockCipherMode: blockCipherMode, padding: padding, mode: .Encrypt)
    }
    
    public static func decrypt(data: Data, key: Data, iv: Data? = nil, algorithm: EncryptionAlgorithm, blockCipherMode: BlockCipherMode = .CBC, padding: Padding = .PKCS7) -> Data? {
        return crypt(data: data, key: key, iv: iv, algorithm: algorithm, blockCipherMode: blockCipherMode, padding: padding, mode: .Decrypt)
    }
    
    private static func crypt(data: Data, key: Data, iv: Data? = nil, algorithm: EncryptionAlgorithm, blockCipherMode: BlockCipherMode = .CBC, padding: Padding = .PKCS7, mode: CryptMode) -> Data? {
        let operation: CCOperation = UInt32(mode == .Encrypt ? kCCEncrypt : kCCDecrypt)
        let cryptAlgorithm: CCAlgorithm = UInt32(algorithm.value)
        var opts: Int = 0
        if blockCipherMode == .ECB {
            opts += kCCOptionECBMode
        }
        if padding == .PKCS7 {
            opts += kCCOptionPKCS7Padding
        }
        let options: CCOptions = UInt32(opts)
        
        var keyData = key
        
        var ivData = Data(count: algorithm.blockSize)
        if let iv = iv { ivData = iv}
        
        if let keyBytes = (keyData.withUnsafeMutableBytes { (unsafeMutableRawBufferPointer) -> UnsafeMutableRawPointer? in
            return unsafeMutableRawBufferPointer.baseAddress}),
            let ivPointer = (ivData.withUnsafeMutableBytes { (unsafeMutableRawBufferPointer) -> UnsafeMutableRawPointer? in
                return unsafeMutableRawBufferPointer.baseAddress}),
            let dataBytes = (data.withUnsafeBytes { (unsafeRawBufferPointer) -> UnsafeRawPointer? in
                return unsafeRawBufferPointer.baseAddress}) {
            
            let keyLength = size_t(keyData.count)
            
            let dataLength = size_t(data.count)
            
            var processedData = Data(count: Int(dataLength) + algorithm.blockSize)
            
            if let cryptPointer = (processedData.withUnsafeMutableBytes { (unsafeMutableRawBufferPointer) -> UnsafeMutableRawPointer? in
                return unsafeMutableRawBufferPointer.baseAddress}) {
                
                let cryptLength = size_t(processedData.count)
                
                var numBytesProcessed: size_t = 0
                
                let cryptStatus = CCCrypt(
                    operation, // operation
                    cryptAlgorithm, // algorithm
                    options, // options
                    keyBytes, // key
                    keyLength, // key length
                    ivPointer, // iv
                    dataBytes, // data in
                    dataLength, // data in length
                    cryptPointer, // data out
                    cryptLength, // data out length
                    &numBytesProcessed // data out moved
                )
                
                if Int(cryptStatus) == Int(kCCSuccess) {
                    return processedData.subdata(in: 0..<numBytesProcessed)
                } else {
                    return nil
                }
            }
            
            return nil
        }
        
        return nil
    }
    
    // PKCS7
    // ********************************************************************************
    
    public static func pkcs7(data: Data, length: Int) -> Data {
        var padding = length - data.count
        let paddingData = Data(bytes: &padding, count: 1)
        var paddedData = Data(data)
        
        if padding > 0 {
            for _ in 0...padding {
                paddedData.append(paddingData)
            }
        }
        
        return paddedData.subdata(in: 0..<length)
    }
    
    // HMAC
    // ********************************************************************************
    
    public static func HMAC(key: Data, message: Data, algorithm: MACAlgorithm) -> Data? {
        let hmacAlgorithm = UInt32(algorithm.value)
        
        let keyData = key
        
        let messageData = message
        
        var data = Data(count: algorithm.macLength)
        
        if let keyBytes = (keyData.withUnsafeBytes { (unsafeRawBufferPointer) -> UnsafeRawPointer? in
            return unsafeRawBufferPointer.baseAddress}),
            let messageBytes = (messageData.withUnsafeBytes { (unsafeRawBufferPointer) -> UnsafeRawPointer? in
                return unsafeRawBufferPointer.baseAddress}),
            let mac = (data.withUnsafeMutableBytes { (unsafeMutableRawBufferPointer) -> UnsafeMutableRawPointer? in
                return unsafeMutableRawBufferPointer.baseAddress}) {
            
            let keyLength = size_t(keyData.count)
            
            let messageLength = size_t(messageData.count)
            
            CCHmac(
                hmacAlgorithm, // algorithm
                keyBytes, // key
                keyLength, // key length
                messageBytes, // data
                messageLength, // data length
                mac // mac
            )
            
            return data
        }
        return nil
    }
    
    // PBKDF2
    // ********************************************************************************
    
    public static func PBKDF2(password: String, salt: Data, iterations: Int, length: Int, algorithm: PRFAlgorithm) -> Data? {
        let pbkdfAlgorithm = UInt32(kCCPBKDF2)
        let passwordData = password.utf8EncodedData!
        
        let prfAlgorithm = UInt32(algorithm.value)
        
        let rounds = UInt32(iterations)
        
        var key = Data(count: length)
        
        if  let passwordBytes = (passwordData.withUnsafeBytes { (unsafeRawBufferPointer) -> UnsafePointer<Int8>? in
            return unsafeRawBufferPointer.baseAddress?.bindMemory(to: Int8.self, capacity: passwordData.count)}),
            let saltBytes = (salt.withUnsafeBytes { (unsafeRawBufferPointer) -> UnsafePointer<UInt8>? in
                return unsafeRawBufferPointer.baseAddress?.bindMemory(to: UInt8.self, capacity: salt.count)}),
            let keyBytes = (key.withUnsafeMutableBytes { (unsafeMutableRawBufferPointer) -> UnsafeMutablePointer<UInt8>? in
                return unsafeMutableRawBufferPointer.baseAddress?.bindMemory(to: UInt8.self, capacity: length)}) {
            
            let passwordLength = size_t(passwordData.count)
            
            let saltLength = size_t(salt.count)
            
            let keyLength = size_t(key.count)
            
            let result = CCKeyDerivationPBKDF(
                pbkdfAlgorithm, // password-based key derivation algorithm
                passwordBytes, // password
                passwordLength, // password length
                saltBytes, // salt
                saltLength, // salt length
                prfAlgorithm, // pseudo random algorithm
                rounds, // rounds
                keyBytes, // key
                keyLength // key length
            )
            
            if Int(result) == Int(kCCSuccess) {
                return key
            } else {
                return nil
            }
        }
        
        return nil
    }
    
    // Hash
    // ********************************************************************************
    
    public static func SHA1(_ text: String) -> String {
        guard let data = text.data(using: String.Encoding.utf8) else {
            return ""
        }
        return SHA1(data)
    }
    
    public static func SHA1(_ data: Data) -> String {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        CC_SHA1((data as NSData).bytes, CC_LONG(data.count), &digest)
        let hexBytes = digest.map { String(format: "%02hhx", $0) }
        return hexBytes.joined(separator: "")
    }
    
    public static func MD5(_ text: String) -> String {
        guard let data = text.data(using: String.Encoding.utf8) else {
            return ""
        }
        return MD5(data)
    }
    
    public static func MD5(_ data: Data) -> String {
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        CC_MD5((data as NSData).bytes, CC_LONG(data.count), &digest)
        let hexBytes = digest.map { String(format: "%02hhx", $0) }
        return hexBytes.joined(separator: "")
    }
    
    // Utilities
    // ********************************************************************************
    
    public static func generateSecureRandomData(length: Int) -> Data? {
        var data = Data(count: length)
        let result = data.withUnsafeMutableBytes { (unsafeMutableRawBufferPointer) -> Int32 in
            if let baseAddress = unsafeMutableRawBufferPointer.baseAddress {
                return SecRandomCopyBytes(kSecRandomDefault, length, baseAddress)
            }
            else {
                return -1
            }
        }
        
        if result == 0 {
            return data
        } else {
            return nil
        }
    }
    
    // Mode
    // ********************************************************************************
    
    public enum CryptMode {
        case Encrypt
        case Decrypt
    }
}

public enum EncryptionAlgorithm {
    case AES128
    case AES192
    case AES256
    case DES
    case TripleDES
    case CAST
    case RC4
    case RC2
    case Blowfish
    
    public var value: Int {
        switch self {
        case .AES128:
            return kCCAlgorithmAES
        case .AES192:
            return kCCAlgorithmAES
        case .AES256:
            return kCCAlgorithmAES
        case .DES:
            return kCCAlgorithmDES
        case .TripleDES:
            return kCCAlgorithm3DES
        case .CAST:
            return kCCAlgorithmCAST
        case .RC4:
            return kCCAlgorithmRC4
        case .RC2:
            return kCCAlgorithmRC2
        case .Blowfish:
            return kCCAlgorithmBlowfish
        }
    }
    
    public var blockSize: Int {
        switch self {
        case .AES128:
            return kCCBlockSizeAES128
        case .AES192:
            return kCCBlockSizeAES128
        case .AES256:
            return kCCBlockSizeAES128
        case .DES:
            return kCCBlockSizeDES
        case .TripleDES:
            return kCCBlockSize3DES
        case .CAST:
            return kCCBlockSizeCAST
        case .RC4:
            return kCCBlockSizeRC2
        case .RC2:
            return kCCBlockSizeRC2
        case .Blowfish:
            return kCCBlockSizeBlowfish
        }
    }
    
    public var minKeySize: Int {
        switch self {
        case .AES128:
            return kCCKeySizeAES128
        case .AES192:
            return kCCKeySizeAES192
        case .AES256:
            return kCCKeySizeAES256
        case .DES:
            return kCCKeySizeDES
        case .TripleDES:
            return kCCKeySize3DES
        case .CAST:
            return kCCKeySizeMinCAST
        case .RC4:
            return kCCKeySizeMinRC4
        case .RC2:
            return kCCKeySizeMinRC2
        case .Blowfish:
            return kCCKeySizeMinBlowfish
        }
    }
    
    public var maxKeySize: Int {
        switch self {
        case .AES128:
            return kCCKeySizeAES128
        case .AES192:
            return kCCKeySizeAES192
        case .AES256:
            return kCCKeySizeAES256
        case .DES:
            return kCCKeySizeDES
        case .TripleDES:
            return kCCKeySize3DES
        case .CAST:
            return kCCKeySizeMaxCAST
        case .RC4:
            return kCCKeySizeMaxRC4
        case .RC2:
            return kCCKeySizeMaxRC2
        case .Blowfish:
            return kCCKeySizeMaxBlowfish
        }
    }
}

public enum Padding {
    case NoPadding
    case PKCS7
}

public enum BlockCipherMode {
    case ECB
    case CBC
}

public enum MACAlgorithm {
    case HMACMD5
    case HMACSHA1
    case HMACSHA224
    case HMACSHA256
    case HMACSHA384
    case HMACSHA512
    
    public var value: Int {
        switch self {
        case .HMACMD5:
            return kCCHmacAlgMD5
        case .HMACSHA1:
            return kCCHmacAlgSHA1
        case .HMACSHA224:
            return kCCHmacAlgSHA224
        case .HMACSHA256:
            return kCCHmacAlgSHA256
        case .HMACSHA384:
            return kCCHmacAlgSHA384
        case .HMACSHA512:
            return kCCHmacAlgSHA512
        }
    }
    
    public var macLength: Int {
        switch self {
        case .HMACMD5:
            return Int(CC_MD5_DIGEST_LENGTH)
        case .HMACSHA1:
            return Int(CC_SHA1_DIGEST_LENGTH)
        case .HMACSHA224:
            return Int(CC_SHA224_DIGEST_LENGTH)
        case .HMACSHA256:
            return Int(CC_SHA256_DIGEST_LENGTH)
        case .HMACSHA384:
            return Int(CC_SHA384_DIGEST_LENGTH)
        case .HMACSHA512:
            return Int(CC_SHA512_DIGEST_LENGTH)
        }
    }
}

public enum PRFAlgorithm {
    case HMACSHA1
    case HMACSHA224
    case HMACSHA256
    case HMACSHA384
    case HMACSHA512
    
    public var value: Int {
        switch self {
        case .HMACSHA1:
            return kCCPRFHmacAlgSHA1
        case .HMACSHA224:
            return kCCPRFHmacAlgSHA224
        case .HMACSHA256:
            return kCCPRFHmacAlgSHA256
        case .HMACSHA384:
            return kCCPRFHmacAlgSHA384
        case .HMACSHA512:
            return kCCPRFHmacAlgSHA512
        }
    }
}
