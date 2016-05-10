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

public typealias GetProductsHandler = (products: [SKProduct], error: NSError?) -> ()

public class IAPHelper: NSObject {
    private let productIdentifiers: Set<String>
    private let handler: IAPHandler
    
    private var restoredProductIdentifiers: [String] = []
    
    public init(productIdentifiers: Set<String>, handler: IAPHandler) {
        self.productIdentifiers = productIdentifiers
        self.handler = handler
        super.init()
        SKPaymentQueue.defaultQueue().addTransactionObserver(self)
    }
    
    deinit {
        SKPaymentQueue.defaultQueue().removeTransactionObserver(self)
        print("Removed self as transaction observer")
    }
    
    public func requestProducts() {
        print("requestProducts")
        let request = SKProductsRequest(productIdentifiers: productIdentifiers)
        request.delegate = self
        request.start()
    }
    
    public func purchaseProduct(product: SKProduct) {
        print("purchaseProduct \(product.productIdentifier)...")
        
        let payment = SKPayment(product: product)
        SKPaymentQueue.defaultQueue().addPayment(payment)
    }
    
    public func restoreCompletedTransactions() {
        SKPaymentQueue.defaultQueue().restoreCompletedTransactions()
    }
    
    public static func canMakePayments() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }
}

extension IAPHelper: SKProductsRequestDelegate {
    public func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
        print("Products request successful")
        let products = response.products
        handler.receivedProducts(products, error: nil)
        
        for product in products {
            print("Product: \(product.productIdentifier) \(product.localizedTitle) \(product.price.floatValue) \(product.priceLocale)")
        }
    }
    
    public func request(request: SKRequest, didFailWithError error: NSError) {
        print("Products request failed: \(error)")
        handler.receivedProducts(nil, error: error)
    }
}

extension IAPHelper: SKPaymentTransactionObserver {
    public func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch (transaction.transactionState) {
            case .Purchasing:
                print("Purchasing")
                handler.purchasing(transaction.payment.productIdentifier)
                break
            case .Deferred:
                print("Deferred")
                handler.deferred(transaction.payment.productIdentifier)
                break
            case .Purchased:
                print("Purchased")
                handler.purchased(transaction.payment.productIdentifier)
                queue.finishTransaction(transaction)
                break
            case .Failed:
                print("Failed")
                handler.failed(transaction.payment.productIdentifier, withError: transaction.error!)
                queue.finishTransaction(transaction)
                break
            case .Restored:
                print("Restored")
                restoredProductIdentifiers.append(transaction.originalTransaction!.payment.productIdentifier)
                queue.finishTransaction(transaction)
                break
            }
        }
    }
    
    public func paymentQueueRestoreCompletedTransactionsFinished(queue: SKPaymentQueue) {
        print("Restore finished: \(restoredProductIdentifiers)")
        handler.restored(restoredProductIdentifiers, error: nil)
        restoredProductIdentifiers.removeAll()
    }
    
    public func paymentQueue(queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: NSError) {
        print("Restore failed")
        handler.restored(nil, error: error)
        restoredProductIdentifiers.removeAll()
    }
}

public protocol IAPHandler {
    func purchasing(productIdentifier: String) -> ()
    func deferred(productIdentifier: String) -> ()
    func purchased(productIdentifier: String) -> ()
    func failed(productIdentifier: String, withError error: NSError) -> ()
    
    func restored(productIdentifiers: [String]?, error: NSError?) -> ()
    
    func receivedProducts(products: [SKProduct]?, error: NSError?) -> ()
}