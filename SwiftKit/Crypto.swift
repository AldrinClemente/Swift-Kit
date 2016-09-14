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
    
    public class Spec {
        public init() {
        }
        
        private var algorithm = EncryptionAlgorithm.AES256
        private var blockCipherMode = BlockCipherMode.CBC
        private var padding = Padding.PKCS7
        private var saltLength = 16
        private var hmacSaltLength = 16
        private var hmacKeyLength = 16
        private var keyDerivationIterations = 10000
        private var prfAlgorithm = PRFAlgorithm.HMACSHA1 // Use HMACSHA1 to ensure data cross-compatibility with Android
        private var macAlgorithm = MACAlgorithm.HMACSHA256
        
        public func setAlgorithm(algorithm: EncryptionAlgorithm) -> Spec {
            self.algorithm = algorithm
            return self
        }
        
        public func setBlockCipherMode(mode: BlockCipherMode) -> Spec {
            self.blockCipherMode = mode
            return self
        }
        
        public func setPadding(padding: Padding) -> Spec {
            self.padding = padding
            return self
        }
        
        public func setSaltLength(length: Int) -> Spec {
            self.saltLength = length
            return self
        }
        
        public func setHMACSaltLength(length: Int) -> Spec {
            self.hmacSaltLength = length
            return self
        }
        
        public func setHMACKeyLength(length: Int) -> Spec {
            self.hmacKeyLength = length
            return self
        }
        
        public func setKeyDerivationIterations(iterations: Int) -> Spec {
            self.keyDerivationIterations = iterations
            return self
        }
        
        public func setPRFAlgorithm(algorithm: PRFAlgorithm) -> Spec {
            self.prfAlgorithm = algorithm
            return self
        }
        
        public func setMACAlgorithm(algorithm: MACAlgorithm) -> Spec {
            self.macAlgorithm = algorithm
            return self
        }
    }
    
    public static func encrypt(data: NSData, password: String, spec: Spec = Spec()) -> NSData? {
        let salt = generateSecureRandomData(spec.saltLength)!
        let key = PBKDF2(password, salt: salt, iterations: spec.keyDerivationIterations, length: spec.algorithm.minKeySize, algorithm: spec.prfAlgorithm)!
        let iv = generateSecureRandomData(spec.algorithm.blockSize)!
        let encryptedData = encrypt(data, key: key, iv: iv, algorithm: spec.algorithm, blockCipherMode: spec.blockCipherMode, padding: spec.padding)!
        
        let hmacSalt = generateSecureRandomData(spec.hmacSaltLength)!
        let hmacKey = PBKDF2(password, salt: hmacSalt, iterations: spec.keyDerivationIterations, length: spec.hmacKeyLength, algorithm: spec.prfAlgorithm)!
        let hmac = HMAC(hmacKey, message: encryptedData, algorithm: spec.macAlgorithm)!
        
        // TODO: Consider adding versioning in case of change in format later
        let message = NSMutableData()
        message.appendData(salt)
        message.appendData(hmacSalt)
        message.appendData(iv)
        message.appendData(encryptedData)
        message.appendData(hmac)
        
        return message
    }
    
    public static func decrypt(encryptedMessage: NSData, password: String, spec: Spec = Spec()) -> NSData? {
        let data = NSMutableData(data: encryptedMessage)
        
        let ivLength = spec.algorithm.blockSize
        let hmacLength = spec.macAlgorithm.macLength
        let encryptedDataLength = encryptedMessage.length - spec.saltLength - spec.hmacSaltLength - ivLength - hmacLength
        
        let saltLocation = 0
        let hmacSaltLocation = saltLocation + spec.saltLength
        let ivLocation = hmacSaltLocation + spec.hmacSaltLength
        let encryptedDataLocation = ivLocation + ivLength
        let hmacLocation = encryptedDataLocation + encryptedDataLength
        
        guard encryptedDataLength > 0 && hmacLocation + hmacLength == encryptedMessage.length else {
            return nil
        }
        
        let salt = NSMutableData(length: spec.saltLength)!
        data.getBytes(UnsafeMutablePointer<Void>(salt.mutableBytes), range: NSRange(location: saltLocation, length: spec.saltLength))
        
        let hmacSalt = NSMutableData(length: spec.hmacSaltLength)!
        data.getBytes(UnsafeMutablePointer<Void>(hmacSalt.mutableBytes), range: NSRange(location: hmacSaltLocation, length: spec.hmacSaltLength))
        
        let iv = NSMutableData(length: ivLength)!
        data.getBytes(UnsafeMutablePointer<Void>(iv.mutableBytes), range: NSRange(location: ivLocation, length: ivLength))
        
        let hmac = NSMutableData(length: hmacLength)!
        data.getBytes(UnsafeMutablePointer<Void>(hmac.mutableBytes), range: NSRange(location: hmacLocation, length: hmacLength))
        
        let encryptedData = NSMutableData(length: encryptedDataLength)!
        data.getBytes(UnsafeMutablePointer<Void>(encryptedData.mutableBytes), range: NSRange(location: encryptedDataLocation, length: encryptedDataLength))
        
        let hmacKey = PBKDF2(password, salt: hmacSalt, iterations: spec.keyDerivationIterations, length: spec.hmacKeyLength, algorithm: spec.prfAlgorithm)!
        guard HMAC(hmacKey, message: encryptedData, algorithm: spec.macAlgorithm) == hmac else {
            return nil
        }
        
        let key = PBKDF2(password, salt: salt, iterations: spec.keyDerivationIterations, length: spec.algorithm.minKeySize, algorithm: spec.prfAlgorithm)!
        
        return decrypt(encryptedData, key: key, iv: iv, algorithm: spec.algorithm, blockCipherMode: spec.blockCipherMode, padding: spec.padding)
    }
    
    
    // Encryption / Decryption
    // ********************************************************************************
    
    public static func encrypt(data: NSData, key: NSData, iv: NSData? = nil, algorithm: EncryptionAlgorithm, blockCipherMode: BlockCipherMode = .CBC, padding: Padding = .PKCS7) -> NSData? {
        return crypt(data, key: key, iv: iv, algorithm: algorithm, blockCipherMode: blockCipherMode, padding: padding, mode: .Encrypt)
    }
    
    public static func decrypt(data: NSData, key: NSData, iv: NSData? = nil, algorithm: EncryptionAlgorithm, blockCipherMode: BlockCipherMode = .CBC, padding: Padding = .PKCS7) -> NSData? {
        return crypt(data, key: key, iv: iv, algorithm: algorithm, blockCipherMode: blockCipherMode, padding: padding, mode: .Decrypt)
    }
    
    private static func crypt(data: NSData, key: NSData, iv: NSData? = nil, algorithm: EncryptionAlgorithm, blockCipherMode: BlockCipherMode = .CBC, padding: Padding = .PKCS7, mode: CryptMode) -> NSData? {
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
        
        let keyData = key
        let keyBytes = UnsafeMutablePointer<Void>(keyData.bytes)
        let keyLength = size_t(keyData.length)
        
        let ivData = iv != nil ? iv! : NSMutableData(length: algorithm.blockSize)!
        let ivPointer = UnsafeMutablePointer<Void>(ivData.bytes)
        
        let dataBytes = UnsafeMutablePointer<Void>(data.bytes)
        let dataLength = size_t(data.length)
        
        let processedData = NSMutableData(length: Int(dataLength) + algorithm.blockSize)!
        let cryptPointer = UnsafeMutablePointer<Void>(processedData.mutableBytes)
        let cryptLength = size_t(processedData.length)
        
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
            processedData.length = Int(numBytesProcessed)
            return processedData
        } else {
            return nil
        }
    }
    
    // PKCS7
    // ********************************************************************************
    
    public static func pkcs7(data: NSData, length: Int) -> NSData {
        var padding = length - data.length
        let paddedData = NSMutableData(data: data)
        
        if padding > 0 {
            for _ in 0...padding {
                paddedData.appendBytes(&padding, length: 1)
            }
        }
        paddedData.length = length
        
        return paddedData
    }
    
    // HMAC
    // ********************************************************************************
    
    public static func HMAC(key: NSData, message: NSData, algorithm: MACAlgorithm) -> NSData? {
        let hmacAlgorithm = UInt32(algorithm.value)
        
        let keyData = key
        let keyBytes = UnsafeMutablePointer<Void>(keyData.bytes)
        let keyLength = size_t(keyData.length)
        
        let messageData = message
        let messageBytes = UnsafeMutablePointer<Void>(messageData.bytes)
        let messageLength = size_t(messageData.length)
        
        let data = NSMutableData(length: algorithm.macLength)!
        let mac = UnsafeMutablePointer<Void>(data.mutableBytes)
        
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
    
    // PBKDF2
    // ********************************************************************************
    
    public static func PBKDF2(password: String, salt: NSData, iterations: Int, length: Int, algorithm: PRFAlgorithm) -> NSData? {
        let pbkdfAlgorithm = UInt32(kCCPBKDF2)
        let passwordData = password.utf8EncodedData!
        let passwordBytes = UnsafeMutablePointer<Int8>(passwordData.bytes)
        let passwordLength = size_t(passwordData.length)
        
        let saltBytes = UnsafeMutablePointer<UInt8>(salt.bytes)
        let saltLength = size_t(salt.length)
        
        let prfAlgorithm = UInt32(algorithm.value)
        
        let rounds = UInt32(iterations)
        
        let key = NSMutableData(length: length)!
        let keyBytes = UnsafeMutablePointer<UInt8>(key.bytes)
        let keyLength = size_t(key.length)
        
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
    
    // Utilities
    // ********************************************************************************
    
    public static func generateSecureRandomData(length: Int) -> NSData? {
        let data = NSMutableData(length: Int(length))!
        let result = SecRandomCopyBytes(kSecRandomDefault, length, UnsafeMutablePointer<UInt8>(data.mutableBytes))
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