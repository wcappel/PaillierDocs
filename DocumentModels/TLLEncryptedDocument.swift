//
//  TLLEncryptedDocument.swift
//  PaillierDocsProject
//
//  Created by Wilton Cappel on 10/25/23.
//

import Foundation
import Bignum

public enum TLLAtomicType {
    case INSERT_NEW_ENTRY
    case ADDITION_ON_ENTRY_VALUE
    case ADDITION_ON_ENTRY_NEXT
    case REMOVE_ENTRY
    // case CHANGE_HEAD_INDEX
}

public enum TLLOperationType {
    case INSERT_NEW_NODE
    case REMOVE_NODE
    case ADDITION_ON_NODE_VALUE
}

public struct EntryOperand {
    var value: PaillierScheme.EncryptedNumber?
    var next: PaillierScheme.EncryptedNumber?
}

public struct TLLAtomicChange {
    let atomicType: TLLAtomicType
    var targetEntryIndex: Int
    var entryOperand: EntryOperand
    
    init(atomicType: TLLAtomicType, targetEntryIndex: Int, entry: EntryOperand) {
        self.atomicType = atomicType
        self.targetEntryIndex = targetEntryIndex
        self.entryOperand = entry
    }
}

public enum TLLOperationError: Error {
    case invalidChangesOrOrderForOperation
    case invalidNumberOfChangesForOperation
}

public struct TLLOperation {
    let operationType: TLLOperationType
    var atomicChanges: [TLLAtomicChange]
    var localRevisionNum: Int
    var ignore: Bool
    
    static func buildInsert(at: Int, entry: EntryOperand, otherNextIndex: Int?, otherNextAddend: PaillierScheme.EncryptedNumber?, localRevisionNum: Int) throws -> Self {
        let insertChange = TLLAtomicChange(atomicType: .INSERT_NEW_ENTRY, targetEntryIndex: at, entry: entry)
        let addChange = (otherNextIndex != nil && otherNextAddend != nil) ? TLLAtomicChange(atomicType: .ADDITION_ON_ENTRY_NEXT, targetEntryIndex: otherNextIndex!, entry: EntryOperand(next: otherNextAddend)) : nil
        
        if let addChange {
            return try Self(operationType: TLLOperationType.INSERT_NEW_NODE, operationChanges: insertChange, addChange, localRevisionNum: localRevisionNum)
        }
        
        return try Self(operationType: TLLOperationType.INSERT_NEW_NODE, operationChanges: insertChange, localRevisionNum: localRevisionNum)
    }
    
    static func buildRemove(at: Int, otherNextIndex: Int?, otherNextAddend: PaillierScheme.EncryptedNumber?, localRevisionNum: Int) throws -> Self {
        let removeChange = TLLAtomicChange(atomicType: .REMOVE_ENTRY, targetEntryIndex: at, entry: EntryOperand(value: nil, next: nil))
        let addChange = (otherNextIndex != nil && otherNextAddend != nil) ? TLLAtomicChange(atomicType: .ADDITION_ON_ENTRY_NEXT, targetEntryIndex: otherNextIndex!, entry: EntryOperand(next: otherNextAddend)) : nil
        
        if let addChange {
            return try Self(operationType: TLLOperationType.REMOVE_NODE, operationChanges: removeChange, addChange, localRevisionNum: localRevisionNum)
        }
        
        return try Self(operationType: TLLOperationType.REMOVE_NODE, operationChanges: removeChange, localRevisionNum: localRevisionNum)
    }
    
    static func buildAddition(at: Int, entryOperand: EntryOperand, localRevisionNum: Int) throws -> Self {
        return try Self(operationType: TLLOperationType.ADDITION_ON_NODE_VALUE, operationChanges: TLLAtomicChange(atomicType: .ADDITION_ON_ENTRY_VALUE, targetEntryIndex: at, entry: entryOperand), localRevisionNum: localRevisionNum)
    }
    
    init(operationType: TLLOperationType, operationChanges: TLLAtomicChange..., localRevisionNum: Int) throws {
        switch operationType {
        case .INSERT_NEW_NODE:
            guard operationChanges.count == 2 || operationChanges.count == 1 else {
                throw TLLOperationError.invalidNumberOfChangesForOperation
            }
            
            if operationChanges.count == 2 {
                guard operationChanges[1].atomicType == .ADDITION_ON_ENTRY_NEXT else {
                    throw TLLOperationError.invalidChangesOrOrderForOperation
                }
            }
            
            guard operationChanges[0].atomicType == .INSERT_NEW_ENTRY else {
                throw TLLOperationError.invalidChangesOrOrderForOperation
            }
        case .REMOVE_NODE:
            guard operationChanges.count == 2 || operationChanges.count == 1 else {
                throw TLLOperationError.invalidNumberOfChangesForOperation
            }
            
            if operationChanges.count == 2 {
                guard operationChanges[1].atomicType == .ADDITION_ON_ENTRY_NEXT else {
                    throw TLLOperationError.invalidChangesOrOrderForOperation
                }
            }
            
            guard operationChanges[0].atomicType == .REMOVE_ENTRY else {
                throw TLLOperationError.invalidChangesOrOrderForOperation
            }
        case .ADDITION_ON_NODE_VALUE:
            guard operationChanges.count == 1 else {
                throw TLLOperationError.invalidNumberOfChangesForOperation
            }
            
            guard operationChanges[0].atomicType == .ADDITION_ON_ENTRY_VALUE else {
                throw TLLOperationError.invalidChangesOrOrderForOperation
            }
        }
        
        self.atomicChanges = []
        self.atomicChanges.append(contentsOf: operationChanges)
        
        self.operationType = operationType
        self.localRevisionNum = localRevisionNum
        self.ignore = false
    }
}

final actor TLLEncryptedDocument {
    private let publicKey: PaillierScheme.PublicKey
    private var textStructure: TableLinkedList<PaillierScheme.EncryptedNumber>
    private var revisionNum: Int
    private var operationHistory: [TLLOperation]
    
    init(publicKey: PaillierScheme.PublicKey) {
        self.publicKey = publicKey
        self.textStructure = TableLinkedList()
        self.revisionNum = 0
        self.operationHistory = []
    }
    
    private func transformOperation(operation: TLLOperation) -> TLLOperation {
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
    
    public func handleOperation(operation: TLLOperation) throws {
        let transformed = transformOperation(operation: operation)
        
        if transformed.ignore { return }
        
        switch transformed.operationType {
        case .INSERT_NEW_NODE:
            if transformed.atomicChanges.count == 2 {
                try self.textStructure.addToEntryNext(nextIndexAddend: transformed.atomicChanges[1].entryOperand.next!, at: transformed.atomicChanges[1].targetEntryIndex)
            }
            try self.textStructure.addEntryAt(value: transformed.atomicChanges[0].entryOperand.value!, nextIndex: transformed.atomicChanges[0].entryOperand.next, at: transformed.atomicChanges[0].targetEntryIndex)
        case .REMOVE_NODE:
            if transformed.atomicChanges.count == 2 {
                try self.textStructure.addToEntryNext(nextIndexAddend: transformed.atomicChanges[1].entryOperand.next!, at: transformed.atomicChanges[1].targetEntryIndex)
            }
            try self.textStructure.removeEntry(at: transformed.atomicChanges[0].targetEntryIndex)
        case .ADDITION_ON_NODE_VALUE:
            try self.textStructure.addToEntryValue(valueAddend: transformed.atomicChanges[0].entryOperand.value!, at: transformed.atomicChanges[0].targetEntryIndex)
        }
        
        self.revisionNum += 1
        self.operationHistory.insert(operation, at: 0)
    }
    
    public func getEncryptedValues() -> [(PaillierScheme.EncryptedNumber, PaillierScheme.EncryptedNumber?)?] {
        let values: [(PaillierScheme.EncryptedNumber, PaillierScheme.EncryptedNumber?)?] = self.textStructure.asTuples()
        // let headIndex: PaillierScheme.EncryptedNumber? = self.textStructure.getEncryptedHeadIndex()
        
        return values
    }
}

