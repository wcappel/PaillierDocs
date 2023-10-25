//
//  File.swift
//  PaillierDocsProject
//
//  Created by Wilton Cappel on 10/25/23.
//

import Foundation
import Bignum

public enum ILLOperationType {
    case INSERT_NEW_NODE
    case ADDITION_ON_NODE_VALUE
    case REMOVE_NODE
    case CHANGE_HEAD
}

public struct ILLOperation {
    let operationType: ILLOperationType
    var targetEntryIndex: Int
    let encryptedOperand: PaillierScheme.EncryptedNumber?
    let encryptedEntryNextIndex: PaillierScheme.EncryptedNumber?
    let localRevisionNum: Int
    var ignore: Bool
    
    init(operationType: ILLOperationType, targetEntryIndex: Int, encryptedOperand: PaillierScheme.EncryptedNumber?, encryptedEntryNextIndex: PaillierScheme.EncryptedNumber?, localRevisionNum: Int) {
        self.operationType = operationType
        self.targetEntryIndex = targetEntryIndex
        self.encryptedOperand = encryptedOperand
        self.encryptedEntryNextIndex = encryptedOperand
        self.localRevisionNum = localRevisionNum
        self.ignore = false
    }
}

final actor ILLEncryptedDocument {
    private let publicKey: PaillierScheme.PublicKey
    private var textStructure: IndexedLinkedList<PaillierScheme.EncryptedNumber>
    private var revisionNum: Int
    private var operationHistory: [ILLOperation]
    
    init(publicKey: PaillierScheme.PublicKey) {
        self.publicKey = publicKey
        self.textStructure = IndexedLinkedList()
        self.revisionNum = 0
        self.operationHistory = []
    }
    
    private func homomorphicOperationalTransform(operation: ILLOperation) -> ILLOperation {
        if operation.localRevisionNum == self.revisionNum {
            return operation
        }
        
        let revisionDiff = self.revisionNum - operation.localRevisionNum
        
        var transformedOperation = operation
        for i in (0...revisionDiff - 1).reversed() {
            switch self.operationHistory[i].operationType {
            case .INSERT_NEW_NODE:
                
            case .REMOVE_NODE:
                
            case .ADDITION_ON_NODE_VALUE:
                
            case .CHANGE_HEAD:
                
            }
        }
        
        return transformedOperation
    }
    
    public func handleOperation(operation: ILLOperation) throws {
        
    }
}

