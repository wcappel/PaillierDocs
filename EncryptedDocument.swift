//
//  Document.swift
//  PaillierDocsProject
//
//  Created by Wilton Cappel on 10/23/23.
//

import Foundation
import Bignum

public enum OperationType {
    case INSERT_NEW_NODE
    case ADDITION_ON_NODE_VALUE
    case REMOVE_NODE
}

public struct Operation {
    let operationType: OperationType
    var targetIndex: Int
    let localRevisionNum: Int
    let encryptedOperand: PaillierScheme.EncryptedNumber?
    var ignore: Bool
    
    init(operationType: OperationType, targetIndex: Int, localRevisionNum: Int, encryptedOperand: PaillierScheme.EncryptedNumber?) {
        self.operationType = operationType
        self.targetIndex = targetIndex
        self.localRevisionNum = localRevisionNum
        self.encryptedOperand = encryptedOperand
        self.ignore = false
    }
}

final actor EncryptedDocument {
    private let publicKey: PaillierScheme.PublicKey
    private var textStructure: SinglyLinkedList<PaillierScheme.EncryptedNumber>
    private var revisionNum: Int
    private var operationHistory: [Operation]
    
    init(publicKey: PaillierScheme.PublicKey) {
        self.publicKey = publicKey
        self.textStructure = SinglyLinkedList()
        self.revisionNum = 0
        self.operationHistory = []
    }
    
    private func transformOperation(operation: Operation) -> Operation {
        if operation.localRevisionNum == self.revisionNum {
            return operation
        }
        
        // Handle local revision num being greater (this shouldn't ever happen)
        
        let revisionDiff = self.revisionNum - operation.localRevisionNum
        
        var transformedOperation = operation
        for i in (0...revisionDiff - 1).reversed() {
            switch self.operationHistory[i].operationType  {
            case .INSERT_NEW_NODE:
                if operation.targetIndex >= operationHistory[i].targetIndex {
                    transformedOperation.targetIndex += 1
                }
            case .REMOVE_NODE:
                if operation.targetIndex <= operationHistory[i].targetIndex {
                    transformedOperation.targetIndex -= 1
                }
            case .ADDITION_ON_NODE_VALUE:
                if operation.targetIndex == operationHistory[i].targetIndex {
                    transformedOperation.ignore = true
                    return transformedOperation
                }
            }
        }
        
//        print("document revision num: \(self.revisionNum), operation local num: \(transformedOperation.localRevisionNum)")
//        print("transformed target index: \(transformedOperation.targetIndex)")
        
        return transformedOperation
    }
    
    public func handleOperation(operation: Operation) throws {
        
        let transformed = transformOperation(operation: operation)
        
        if transformed.ignore { return }
        
        switch transformed.operationType {
        case .ADDITION_ON_NODE_VALUE:
            try self.textStructure.addAtIndex(addend: transformed.encryptedOperand!, index: transformed.targetIndex)
        case .INSERT_NEW_NODE:
            try self.textStructure.insertAfter(transformed.encryptedOperand!, index: transformed.targetIndex)
        case .REMOVE_NODE:
            try self.textStructure.removeAt(index: transformed.targetIndex)
        }
        
        
        self.revisionNum += 1
        self.operationHistory.insert(operation, at: 0)
    }
    
    public func getEncryptedValues() -> [PaillierScheme.EncryptedNumber] {
        return self.textStructure.asArray()
    }
}
