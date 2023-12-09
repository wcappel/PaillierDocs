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
}

public enum TLLOperationType {
    case INSERT_OR_DELETE_NODE
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
    
    static func buildInsertOrRemove(at: Int, entry: EntryOperand, otherNextIndex: Int?, otherNextAddend: PaillierScheme.EncryptedNumber?, localRevisionNum: Int) throws -> Self {
        let insertOrRemoveChange = TLLAtomicChange(atomicType: .INSERT_NEW_ENTRY, targetEntryIndex: at, entry: entry)
        let addChange = (otherNextIndex != nil && otherNextAddend != nil) ? TLLAtomicChange(atomicType: .ADDITION_ON_ENTRY_NEXT, targetEntryIndex: otherNextIndex!, entry: EntryOperand(next: otherNextAddend)) : nil
        
        if let addChange {
            return try Self(operationType: TLLOperationType.INSERT_OR_DELETE_NODE, operationChanges: insertOrRemoveChange, addChange, localRevisionNum: localRevisionNum)
        }
        
        return try Self(operationType: TLLOperationType.INSERT_OR_DELETE_NODE, operationChanges: insertOrRemoveChange, localRevisionNum: localRevisionNum)
    }
    
    static func buildAddition(at: Int, entryOperand: EntryOperand, localRevisionNum: Int) throws -> Self {
        return try Self(operationType: TLLOperationType.ADDITION_ON_NODE_VALUE, operationChanges: TLLAtomicChange(atomicType: .ADDITION_ON_ENTRY_VALUE, targetEntryIndex: at, entry: entryOperand), localRevisionNum: localRevisionNum)
    }
    
    init(operationType: TLLOperationType, operationChanges: TLLAtomicChange..., localRevisionNum: Int) throws {
        switch operationType {
        case .INSERT_OR_DELETE_NODE:
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
    public var revisionNum: Int
    private var operationHistory: [TLLOperation]
    public static let INITIALIZED_NUM_OF_ENTRIES: Int = 50
    private let zeroedCiphertext: PaillierScheme.EncryptedNumber
    private let defaultIndexCiphertext: PaillierScheme.EncryptedNumber

    
    init(publicKey: PaillierScheme.PublicKey) {
        self.publicKey = publicKey
        self.textStructure = TableLinkedList()
        self.revisionNum = 0
        self.operationHistory = []
        
        self.zeroedCiphertext = publicKey.encrypt(plaintext: 0)
        self.defaultIndexCiphertext = publicKey.encrypt(plaintext: -1)
        
        for _ in 0...Self.INITIALIZED_NUM_OF_ENTRIES - 1 {
            self.textStructure.addEntry(value: self.zeroedCiphertext, nextIndex: self.defaultIndexCiphertext)
        }
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
        case .INSERT_OR_DELETE_NODE:
            if transformed.atomicChanges.count == 2 {
                try self.textStructure.addToEntryNext(nextIndexAddend: transformed.atomicChanges[1].entryOperand.next!, at: transformed.atomicChanges[1].targetEntryIndex)
            }
            try self.textStructure.addToEntryValue(valueAddend: transformed.atomicChanges[0].entryOperand.value ?? zeroedCiphertext, at: transformed.atomicChanges[0].targetEntryIndex)
            try self.textStructure.addToEntryNext(nextIndexAddend: transformed.atomicChanges[0].entryOperand.next ?? zeroedCiphertext, at: transformed.atomicChanges[0].targetEntryIndex)
        case .ADDITION_ON_NODE_VALUE:
            try self.textStructure.addToEntryValue(valueAddend: transformed.atomicChanges[0].entryOperand.value!, at: transformed.atomicChanges[0].targetEntryIndex)
        }
        
        self.revisionNum += 1
        self.operationHistory.insert(operation, at: 0)
    }
    
    private func resize() {
        let targetMagnitude = ((self.textStructure.size / Self.INITIALIZED_NUM_OF_ENTRIES) + 1) * 2
        
        for _ in 1...(targetMagnitude - self.textStructure.size) {
            self.textStructure.addEntry(value: self.zeroedCiphertext, nextIndex: self.defaultIndexCiphertext)
        }
    }
    
    public func getEncryptedValues() -> [(PaillierScheme.EncryptedNumber, PaillierScheme.EncryptedNumber?)?] {
        let values: [(PaillierScheme.EncryptedNumber, PaillierScheme.EncryptedNumber?)?] = self.textStructure.asTuples()
        
        return values
    }
}

