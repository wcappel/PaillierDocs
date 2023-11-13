//
//  ILLEncryptedDocument.swift
//  PaillierDocsProject
//
//  Created by Wilton Cappel on 10/25/23.
//

import Foundation
import Bignum

public enum ILLAtomicType {
    case INSERT_NEW_ENTRY
    case ADDITION_ON_ENTRY_VALUE
    case ADDITION_ON_ENTRY_NEXT
    case REMOVE_ENTRY
    case CHANGE_HEAD_INDEX
}

public enum ILLOperationType {
    case INSERT_NEW_NODE
    case REMOVE_NODE
    case ADDITION_ON_NODE_VALUE
}

public struct EntryOperand {
    var value: PaillierScheme.EncryptedNumber?
    var next: PaillierScheme.EncryptedNumber?
}

public struct ILLAtomicChange {
    let atomicType: ILLAtomicType
    var targetEntryIndex: Int
    var entryOperand: EntryOperand
    
    init(atomicType: ILLAtomicType, targetEntryIndex: Int, entry: EntryOperand) {
        self.atomicType = atomicType
        self.targetEntryIndex = targetEntryIndex
        self.entryOperand = entry
    }
}

public enum ILLOperationError: Error {
    case invalidChangesOrOrderForOperation
    case invalidNumberOfChangesForOperation
}

public struct ILLOperation {
    let operationType: ILLOperationType
    var atomicChanges: [ILLAtomicChange]
    var localRevisionNum: Int
    var ignore: Bool
    
    static func buildInsert(at: Int, entry: EntryOperand, otherNextIndex: Int, otherNextAddend: PaillierScheme.EncryptedNumber, localRevisionNum: Int) throws -> Self {
        let insertChange = ILLAtomicChange(atomicType: .INSERT_NEW_ENTRY, targetEntryIndex: at, entry: entry)
        let addChange = ILLAtomicChange(atomicType: .ADDITION_ON_ENTRY_NEXT, targetEntryIndex: otherNextIndex, entry: EntryOperand(next: otherNextAddend))
        
        return try Self(operationType: ILLOperationType.INSERT_NEW_NODE, operationChanges: addChange, insertChange, localRevisionNum: localRevisionNum)
    }
    
    static func buildRemove(at: Int, otherNextIndex: Int, otherNextAddend: PaillierScheme.EncryptedNumber, localRevisionNum: Int) throws -> Self {
        let removeChange = ILLAtomicChange(atomicType: .REMOVE_ENTRY, targetEntryIndex: at, entry: EntryOperand(value: nil, next: nil))
        let addChange = ILLAtomicChange(atomicType: .ADDITION_ON_ENTRY_NEXT, targetEntryIndex: otherNextIndex, entry: EntryOperand(next: otherNextAddend))
        
        return try Self(operationType: ILLOperationType.REMOVE_NODE, operationChanges: removeChange, addChange, localRevisionNum: localRevisionNum)
    }
    
    static func buildAddition(at: Int, entryOperand: EntryOperand, localRevisionNum: Int) throws -> Self {
        return try Self(operationType: ILLOperationType.ADDITION_ON_NODE_VALUE, operationChanges: ILLAtomicChange(atomicType: .ADDITION_ON_ENTRY_VALUE, targetEntryIndex: at, entry: entryOperand), localRevisionNum: localRevisionNum)
    }
    
    init(operationType: ILLOperationType, operationChanges: ILLAtomicChange..., localRevisionNum: Int) throws {
        switch operationType {
        case .INSERT_NEW_NODE:
            guard operationChanges.count == 2 else {
                throw ILLOperationError.invalidNumberOfChangesForOperation
            }
            
            guard operationChanges[0].atomicType == .ADDITION_ON_ENTRY_VALUE
            && operationChanges[1].atomicType == .ADDITION_ON_ENTRY_NEXT else {
                throw ILLOperationError.invalidChangesOrOrderForOperation
            }
        case .REMOVE_NODE:
            guard operationChanges.count == 2 else {
                throw ILLOperationError.invalidNumberOfChangesForOperation
            }
            
            guard operationChanges[0].atomicType == .REMOVE_ENTRY
            && operationChanges[1].atomicType == .ADDITION_ON_ENTRY_NEXT else {
                throw ILLOperationError.invalidChangesOrOrderForOperation
            }
            
        case .ADDITION_ON_NODE_VALUE:
            guard operationChanges.count == 1 else {
                throw ILLOperationError.invalidNumberOfChangesForOperation
            }
            
            guard operationChanges[0].atomicType == .ADDITION_ON_ENTRY_VALUE else {
                throw ILLOperationError.invalidChangesOrOrderForOperation
            }
        }
        
        self.atomicChanges = []
        self.atomicChanges.append(contentsOf: atomicChanges)
        
        self.operationType = operationType
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
    
    private func transformOperation(operation: ILLOperation) -> ILLOperation {
        if operation.localRevisionNum == self.revisionNum {
            return operation
        }
        
        let revisionDiff = self.revisionNum - operation.localRevisionNum
        
        var transformedOperation = operation
        for i in (0...revisionDiff - 1).reversed() {
//            switch self.operationHistory[i].operationType {
//
//            case .INSERT_NEW_NODE:
//                if self.operationHistory[i].atomicChanges[0].targetEntryIndex >= transformedOperation.atomicChanges[0].targetEntryIndex {
//
//                }
//            case .REMOVE_NODE:
//
//            case .ADDITION_ON_NODE_VALUE:
//                if self.operationHistory[i].operationType == .ADDITION_ON_NODE_VALUE && self.operationHistory[i].atomicChanges[0].targetEntryIndex == transformedOperation.atomicChanges[0].targetEntryIndex {
//                    transformedOperation.ignore = true
//                }
//            }
        }
        
        return transformedOperation
    }
    
    public func handleOperation(operation: ILLOperation) throws {
        let transformed = transformOperation(operation: operation)
        
        if transformed.ignore { return }
        
        switch transformed.operationType {
        case .INSERT_NEW_NODE:
            try self.textStructure.addToEntryNext(nextIndexAddend: transformed.atomicChanges[1].entryOperand.next!, at: transformed.atomicChanges[1].targetEntryIndex)
            try self.textStructure.addEntryAt(value: transformed.atomicChanges[0].entryOperand.value!, nextIndex: transformed.atomicChanges[0].entryOperand.next!, at: transformed.atomicChanges[0].targetEntryIndex)
        case .REMOVE_NODE:
            try self.textStructure.addToEntryNext(nextIndexAddend: transformed.atomicChanges[1].entryOperand.next!, at: transformed.atomicChanges[1].targetEntryIndex)
            try self.textStructure.removeEntry(at: transformed.atomicChanges[0].targetEntryIndex)
        case .ADDITION_ON_NODE_VALUE:
            try self.textStructure.addToEntryValue(valueAddend: transformed.atomicChanges[0].entryOperand.value!, at: transformed.atomicChanges[0].targetEntryIndex)
        }
        
        self.revisionNum += 1
        self.operationHistory.insert(operation, at: 0)
    }
    
    public func getEncryptedValues() -> (PaillierScheme.EncryptedNumber?, [(PaillierScheme.EncryptedNumber, PaillierScheme.EncryptedNumber)?]) {
        let values: [(PaillierScheme.EncryptedNumber, PaillierScheme.EncryptedNumber)?] = self.textStructure.asTuples()
        let headIndex: PaillierScheme.EncryptedNumber? = self.textStructure.getEncryptedHeadIndex()
        
        return (headIndex, values)
    }
}

