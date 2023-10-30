//
//  File.swift
//  PaillierDocsProject
//
//  Created by Wilton Cappel on 10/25/23.
//

import Foundation
import Bignum

public enum ILLOperationType {
    case INSERT_NEW_ENTRY
    case ADDITION_ON_ENTRY_VALUE
    case ADDITION_ON_ENTRY_NEXT
    case REMOVE_ENTRY
    case CHANGE_HEAD_INDEX
}

public struct EntryOperand {
    var value: PaillierScheme.EncryptedNumber?
    var next: PaillierScheme.EncryptedNumber?
}

public struct ILLOperation {
    let operationType: ILLOperationType
    var targetEntryIndex: Int
    var entryOperand: EntryOperand
    let localRevisionNum: Int
    var ignore: Bool
    
    init(operationType: ILLOperationType, targetEntryIndex: Int, entry: EntryOperand, localRevisionNum: Int) {
        self.operationType = operationType
        self.targetEntryIndex = targetEntryIndex
        self.entryOperand = entry
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
//            switch self.operationHistory[i].operationType {
//            case .INSERT_NEW_ENTRY:
//
//            case .REMOVE_ENTRY:
//
//            case .ADDITION_ON_ENTRY_VALUE:
//                if operation.targetEntryIndex == operationHistory[i].targetEntryIndex {
//                    transformedOperation.ignore = true
//                    return transformedOperation
//                }
//            case .ADDITION_ON_ENTRY_NEXT:
//
//            case .CHANGE_HEAD_INDEX:
//                transformedOperation.ignore = true
//                return transformedOperation
//            }
        }
        
        return transformedOperation
    }
    
    public func handleOperation(operation: ILLOperation) throws {
        let transformed = homomorphicOperationalTransform(operation: operation)
        
        if transformed.ignore { return }
        
        switch transformed.operationType {
        case .ADDITION_ON_ENTRY_VALUE:
            try self.textStructure.addToEntryValue(valueAddend: operation.entryOperand.value!, at: operation.targetEntryIndex)
        case .ADDITION_ON_ENTRY_NEXT:
            try self.textStructure.addToEntryNext(nextIndexAddend: operation.entryOperand.next!, at: operation.targetEntryIndex)
        case .INSERT_NEW_ENTRY:
            try self.textStructure.addEntryAt(value: operation.entryOperand.value!, nextIndex: operation.entryOperand.next!, at: operation.targetEntryIndex)
        case .REMOVE_ENTRY:
            try self.textStructure.removeEntry(at: operation.targetEntryIndex)
        case .CHANGE_HEAD_INDEX:
            try self.textStructure.changeHeadIndex(newHeadIndex: operation.entryOperand.value!)
        }
        
        self.revisionNum += 1
        self.operationHistory.insert(operation, at: 0)
    }
}

