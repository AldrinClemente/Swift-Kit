//
// IAPHelper.swift
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
import StoreKit

public typealias GetProductsHandler = (_ products: [SKProduct], _ error: NSError?) -> ()

open class IAPHelper: NSObject {
    fileprivate let productIdentifiers: Set<String>
    fileprivate let handler: IAPHandler
    
    fileprivate var restoredProductIdentifiers: [String] = []
    
    public init(productIdentifiers: Set<String>, handler: IAPHandler) {
        self.productIdentifiers = productIdentifiers
        self.handler = handler
        super.init()
        SKPaymentQueue.default().add(self)
    }
    
    deinit {
        SKPaymentQueue.default().remove(self)
        print("Removed self as transaction observer")
    }
    
    open func requestProducts() {
        print("requestProducts")
        let request = SKProductsRequest(productIdentifiers: productIdentifiers)
        request.delegate = self
        request.start()
    }
    
    open func purchaseProduct(_ product: SKProduct) {
        print("purchaseProduct \(product.productIdentifier)...")
        
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    open func restoreCompletedTransactions() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    public static func canMakePayments() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }
}

extension IAPHelper: SKProductsRequestDelegate {
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        print("Products request successful")
        let products = response.products
        handler.receivedProducts(products, error: nil)
        
        for product in products {
            print("Product: \(product.productIdentifier) \(product.localizedTitle) \(product.price.floatValue) \(product.priceLocale)")
        }
    }
    
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        print("Products request failed: \(error)")
        handler.receivedProducts(nil, error: error as NSError?)
    }
}

extension IAPHelper: SKPaymentTransactionObserver {
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch (transaction.transactionState) {
            case .purchasing:
                print("Purchasing")
                handler.purchasing(transaction.payment.productIdentifier)
                break
            case .deferred:
                print("Deferred")
                handler.deferred(transaction.payment.productIdentifier)
                break
            case .purchased:
                print("Purchased")
                handler.purchased(transaction.payment.productIdentifier)
                queue.finishTransaction(transaction)
                break
            case .failed:
                print("Failed")
                if let transactionError = transaction.error {
                    handler.failed(transaction.payment.productIdentifier, withError: transactionError as NSError)}
                queue.finishTransaction(transaction)
                break
            case .restored:
                print("Restored")
                restoredProductIdentifiers.append(transaction.original?.payment.productIdentifier ?? String.init())
                queue.finishTransaction(transaction)
                break
            @unknown default:
                break
            }
        }
    }
    
    public func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        print("Restore finished: \(restoredProductIdentifiers)")
        handler.restored(restoredProductIdentifiers, error: nil)
        restoredProductIdentifiers.removeAll()
    }
    
    public func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        print("Restore failed")
        handler.restored(nil, error: error as NSError?)
        restoredProductIdentifiers.removeAll()
    }
}

public protocol IAPHandler {
    func purchasing(_ productIdentifier: String) -> ()
    func deferred(_ productIdentifier: String) -> ()
    func purchased(_ productIdentifier: String) -> ()
    func failed(_ productIdentifier: String, withError error: NSError) -> ()
    
    func restored(_ productIdentifiers: [String]?, error: NSError?) -> ()
    
    func receivedProducts(_ products: [SKProduct]?, error: NSError?) -> ()
}
