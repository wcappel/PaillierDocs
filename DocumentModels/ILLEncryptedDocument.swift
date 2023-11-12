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
    
    init(atomicType: ILLAtomicType, targetEntryIndex: Int, entry: EntryOperand, localRevisionNum: Int) {
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
        let insertChange = ILLAtomicChange(atomicType: .INSERT_NEW_ENTRY, targetEntryIndex: at, entry: entry, localRevisionNum: localRevisionNum)
        let addChange = ILLAtomicChange(atomicType: .ADDITION_ON_ENTRY_NEXT, targetEntryIndex: otherNextIndex, entry: EntryOperand(next: otherNextAddend), localRevisionNum: localRevisionNum)
        
        return try Self(operationType: ILLOperationType.INSERT_NEW_NODE, atomicChanges: addChange, insertChange, localRevisionNum: localRevisionNum)
    }
    
    static func buildRemove() -> Self {
        
    }
    
    static func buildAddition() -> Self {
        
    }
    
    init(operationType: ILLOperationType, atomicChanges: ILLAtomicChange..., localRevisionNum: Int) throws {
        switch operationType {
        case .INSERT_NEW_NODE:
            guard atomicChanges.count == 2 else {
                throw ILLOperationError.invalidNumberOfChangesForOperation
            }
            
            guard atomicChanges[0].atomicType == .ADDITION_ON_ENTRY_VALUE
            && atomicChanges[1].atomicType == .ADDITION_ON_ENTRY_NEXT else {
                throw ILLOperationError.invalidChangesOrOrderForOperation
            }
        case .REMOVE_NODE:
            guard atomicChanges.count == 2 else {
                throw ILLOperationError.invalidNumberOfChangesForOperation
            }
            
            guard atomicChanges[0].atomicType == .REMOVE_ENTRY
            && atomicChanges[1].atomicType == .ADDITION_ON_ENTRY_NEXT else {
                throw ILLOperationError.invalidChangesOrOrderForOperation
            }
            
            self.atomicChanges.append(contentsOf: atomicChanges)
        case .ADDITION_ON_NODE_VALUE:
            guard atomicChanges.count == 1 else {
                throw ILLOperationError.invalidNumberOfChangesForOperation
            }
            
            guard atomicChanges[0].atomicType == .ADDITION_ON_ENTRY_VALUE else {
                throw ILLOperationError.invalidChangesOrOrderForOperation
            }
        }
        
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
    
    private func homomorphicOperationalTransform(operation: ILLOperation) -> ILLOperation {
        if operation.localRevisionNum == self.revisionNum {
            return operation
        }
        
        let revisionDiff = self.revisionNum - operation.localRevisionNum
        
        var transformedOperation = operation
        for i in (0...revisionDiff - 1).reversed() {
            switch self.operationHistory[i].operationType {
                
            case .INSERT_NEW_NODE:
                <#code#>
            case .REMOVE_NODE:
                <#code#>
            case .ADDITION_ON_NODE_VALUE:
                <#code#>
            }
        }
        
        return transformedOperation
    }
    
    public func handleOperation(operation: ILLOperation) throws {
        let transformed = homomorphicOperationalTransform(operation: operation)
        
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
}

