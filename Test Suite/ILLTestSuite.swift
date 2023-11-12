//
//  ILLTestSuite.swift
//  
//
//  Created by Wilton Cappel on 11/10/23.
//

import Foundation

class ILLTestSuite {
    private var encryptedDoc: ILLEncryptedDocument
    private var localRevisionNum: Int
    private var knownHistory: [ILLOperation]
    
    public init(doc: ILLEncryptedDocument) {
        self.encryptedDoc = doc
        self.localRevisionNum = 0
        self.knownHistory = []
    }
    
    public func perform(operation: ILLOperation, laggingBy: Int = 0) async {
        assert(laggingBy >= 0)
        do {
            try await encryptedDoc.handleOperation(operation: operation)
            knownHistory.append(operation)
            self.showDocument()
        } catch {
            print(error)
        }
    }
    
    public func showDocument() {
        // Shows encrypted and plaintext versions of document
    }
    
    public func showHistory() {
        
    }
    
}
