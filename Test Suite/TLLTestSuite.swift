//
//  TLLTestSuite.swift
//  
//
//  Created by Wilton Cappel on 11/10/23.
//

import Foundation
import Bignum

class TLLTestSuite {
    private var encryptedDoc: TLLEncryptedDocument
    private let privKey: PaillierScheme.PrivateKey
    private var localRevisionNum: Int
    private var knownHistory: [TLLOperation]
    
    public init(doc: TLLEncryptedDocument, privKey: PaillierScheme.PrivateKey) {
        self.encryptedDoc = doc
        self.privKey = privKey
        self.localRevisionNum = 0
        self.knownHistory = []
    }
    
    public func perform(operation: TLLOperation, laggingBy: Int = 0) async {
        assert(laggingBy >= 0)
        do {
            var copiedOperation = operation
            if laggingBy > 0 {
                copiedOperation.localRevisionNum = await encryptedDoc.revisionNum - laggingBy
            }
            try await encryptedDoc.handleOperation(operation: copiedOperation)
            self.localRevisionNum += 1
            knownHistory.append(copiedOperation)
//            try await self.showDocument()
        } catch {
            print(error)
        }
    }
    
    public func showDocument() async throws {
        let decrypted = try await decryptTLLDocument(doc: self.encryptedDoc, privateKey: self.privKey)
        var strResult = ""
        print("DECRYPTED DOCUMENT:")
        for d in decrypted {
            if let d, d.0 != 0 {
                let nextIndex = d.1 == -1 ? "X" : (d.1?.string(base: 10) ?? "NIL")
                strResult += "\t\t[\(String(bytes: d.0.fromSingleChunkEncoding(), encoding: .utf8)!), \(nextIndex)]\n"
            } else if let d, d.0 == 0 {
                let nextIndex = d.1 == -1 ? "X" : (d.1?.string(base: 10) ?? "NIL")
                strResult += "\t\t[\\0, \(nextIndex)]\n"
            } else {
                strResult += "\t\tNULL\n"
            }
        }
        
        print("\tREVISION NUM = \(self.localRevisionNum)")
        print(strResult)
    }
    
    public func showHistory() {
        var strResult = "\t"
        for (i, h) in self.knownHistory.enumerated() {
            strResult += "\(i): \(h.operationType) — at \(h.atomicChanges[0].targetEntryIndex)"
            if h.atomicChanges.count == 2 {
                strResult += ", at \(h.atomicChanges[1].targetEntryIndex)"
            }
            strResult += "\n\t"
        }
        
        print("DOCUMENT OPERATION HISTORY")
        print(strResult)
    }
    
    public func scenario_straightAppendsWithEdits(fakeOperations: Bool = false) async {
        var addedChunks: [Int] = []
        let indicesRange = 0...TLLEncryptedDocument.INITIALIZED_NUM_OF_ENTRIES - 1
        
        for _ in 0...14 {
            var newChunk = Int.random(in: indicesRange)
            while addedChunks.contains(newChunk) {
                newChunk = Int.random(in: indicesRange)
            }
            
            let operation = try! await addedChunks.count == 0 ?
            TLLOperation.buildInsertOrRemove(at: newChunk, entry: EntryOperand(value: pubKey.encrypt(plaintext: BigInt.randomInt(bits: 31))), otherNextIndex: nil, otherNextAddend: nil, localRevisionNum: encryptedDoc.revisionNum) :
            TLLOperation.buildInsertOrRemove(at: newChunk, entry: EntryOperand(value: pubKey.encrypt(plaintext: BigInt.randomInt(bits: 31))), otherNextIndex: addedChunks.last!, otherNextAddend: pubKey.encrypt(plaintext: BigInt(newChunk)), localRevisionNum: encryptedDoc.revisionNum)
            
            await self.perform(operation: operation)
            addedChunks.append(newChunk)
            
            let numEditsBetweenAdd = addedChunks.count == 0 ? 0 : Int.random(in: 0...5)
            
            for _ in 0...numEditsBetweenAdd {
                let editedChunkIndex = addedChunks[Int.random(in: 0...addedChunks.count - 1)]
                let editOperation = try! await TLLOperation.buildAddition(at: editedChunkIndex, entryOperand: EntryOperand(value: pubKey.encrypt(plaintext: 0)), localRevisionNum: encryptedDoc.revisionNum)
                
                await self.perform(operation: editOperation)
            }
        }
        self.trackHistoryAttempt(assumeNoFaking: !fakeOperations)
    }
    
    public func scenario_variedAppendsAndRemovesWithEdits(fakeOperations: Bool = false) async {
        var mirroredLinkedList = SinglyLinkedList<Int>()
        let indicesRange = 0...TLLEncryptedDocument.INITIALIZED_NUM_OF_ENTRIES - 1
        
        for _ in 0...19 {
            let isRemove = Int.random(in: 0...1) == 1 && mirroredLinkedList.size > 0
            if isRemove {
                let removeIndex = Int.random(in: 0...mirroredLinkedList.size - 1)
                let nodeIndex = try! mirroredLinkedList.getAt(removeIndex)
                let prevIndex: Int? = removeIndex == 0 ? nil : try! mirroredLinkedList.getAt(removeIndex - 1)
                if let prevIndex {
                    let valueAtPrevIndex = try! await privKey.decrypt(encryptedNumber: encryptedDoc.getEncryptedValues()[prevIndex]!.1!)
                    let operation = try! await TLLOperation.buildInsertOrRemove(at: nodeIndex, entry: EntryOperand(value: pubKey.encrypt(plaintext: -BigInt.randomInt(bits: 31))), otherNextIndex: prevIndex, otherNextAddend: pubKey.encrypt(plaintext: -valueAtPrevIndex), localRevisionNum: encryptedDoc.revisionNum)
                    await self.perform(operation: operation)
                } else {
                    let operation = try! await TLLOperation.buildInsertOrRemove(at: nodeIndex, entry: EntryOperand(value: pubKey.encrypt(plaintext: -BigInt.randomInt(bits: 31))), otherNextIndex: nil, otherNextAddend: nil, localRevisionNum: encryptedDoc.revisionNum)
                    await self.perform(operation: operation)
                }
                try! mirroredLinkedList.removeAt(index: removeIndex)
            } else {
                var newChunkEntryIndex = Int.random(in: indicesRange)
                while mirroredLinkedList.getIndicesOfValue(value: newChunkEntryIndex).count != 0 {
                    newChunkEntryIndex = Int.random(in: indicesRange)
                }
                let addIndex = mirroredLinkedList.size > 0 ? Int.random(in: 0...mirroredLinkedList.size - 1) : 0
                let prevIndex: Int? = addIndex == 0 ? nil : try! mirroredLinkedList.getAt(addIndex)
                if let prevIndex {
                    let valueAtPrevIndex = try! await privKey.decrypt(encryptedNumber: encryptedDoc.getEncryptedValues()[prevIndex]!.1!)
                    let operation = try! await TLLOperation.buildInsertOrRemove(at: newChunkEntryIndex, entry: EntryOperand(value: pubKey.encrypt(plaintext: BigInt.randomInt(bits: 31))), otherNextIndex: prevIndex, otherNextAddend: pubKey.encrypt(plaintext: -valueAtPrevIndex + newChunkEntryIndex), localRevisionNum: encryptedDoc.revisionNum)
                    await self.perform(operation: operation)
                } else {
                    let operation = try! await TLLOperation.buildInsertOrRemove(at: Int.random(in: indicesRange), entry: EntryOperand(value: pubKey.encrypt(plaintext: BigInt.randomInt(bits: 31))), otherNextIndex: nil, otherNextAddend: nil, localRevisionNum: encryptedDoc.revisionNum)
                    await self.perform(operation: operation)
                }
                try! mirroredLinkedList.insertAt(newChunkEntryIndex, index: addIndex)
            }
            
            guard mirroredLinkedList.size > 0 else {
                continue
            }
            
            let numEditsBetweenOperation = mirroredLinkedList.size == 0 ? 0 : Int.random(in: 0...5)
            for _ in 0...numEditsBetweenOperation {
                print(mirroredLinkedList.size)
                let editedChunkIndex = try! mirroredLinkedList.size > 0 ? mirroredLinkedList.getAt(Int.random(in: 0...mirroredLinkedList.size - 1)) : mirroredLinkedList.getAt(0)
                let editOperation = try! await TLLOperation.buildAddition(at: editedChunkIndex, entryOperand: EntryOperand(value: pubKey.encrypt(plaintext: 0)), localRevisionNum: encryptedDoc.revisionNum)
                
                await self.perform(operation: editOperation)
            }
        }
        self.trackHistoryAttempt(assumeNoFaking: !fakeOperations)
    }
    
    public func trackHistoryAttempt(assumeNoFaking: Bool) {
        var absolutePositionEstimateRangeForHistoryItems: [Int : (Int, Int)] = [:]
        var mimicLinkedListsForHistoryItems: [[SinglyLinkedList<Int>]] = []
//        print(self.knownHistory)
        
        for (i, h): (Int, TLLOperation) in self.knownHistory.enumerated() {
            if i == 0 {
                var startingMimic = SinglyLinkedList<Int>()
                startingMimic.append(h.atomicChanges[0].targetEntryIndex)
                absolutePositionEstimateRangeForHistoryItems[0] = (0, 0)
                mimicLinkedListsForHistoryItems.append([startingMimic])
                print("\(i): \(absolutePositionEstimateRangeForHistoryItems[i]!)")
                continue // Assume first operation is add
            }
            
            let previousHistoryItemMimics = mimicLinkedListsForHistoryItems.last!
            var positionGuesses: Set<Int> = Set<Int>()
            
            switch h.operationType {
            case .INSERT_OR_DELETE_NODE:
                let primaryChunkIndex = h.atomicChanges[0].targetEntryIndex
                let prevChunkIndex: Int? = h.atomicChanges.count > 1 ? h.atomicChanges[1].targetEntryIndex : nil
                
                var branches: [SinglyLinkedList<Int>] = []
                
                if !assumeNoFaking {
                    branches.append(contentsOf: previousHistoryItemMimics)
                }
                
                // If there's no prev entry next value addition, it's definitely at the first node
                if h.atomicChanges.count == 1 {
                    var newMimics: [SinglyLinkedList<Int>] = []
                    for m in previousHistoryItemMimics {
                        var cloned = m.clone()
                        cloned.prepend(primaryChunkIndex)
                        newMimics.append(cloned)
                    }
                    
                    absolutePositionEstimateRangeForHistoryItems[i] = (0, 0)
                    mimicLinkedListsForHistoryItems.append(newMimics)
                    print("\(i): \(absolutePositionEstimateRangeForHistoryItems[i]!)")
                    continue
                }
                
                // In order to distinguish an add from a remove, we need to check if there is an entry index not used before
                var unusedEntryIndex: Int?
                
                if previousHistoryItemMimics[0].getIndicesOfValue(value: primaryChunkIndex).count == 0 {
                    unusedEntryIndex = primaryChunkIndex
                }
    
                if let unusedEntryIndex {
                    // Determine the position of the added chunk in relation by its prev entry next pointer
                    for m in previousHistoryItemMimics {
                        var prevIndex: Int?
                        if let prevChunkIndex {
                            let valueIndices = m.getIndicesOfValue(value: prevChunkIndex)
                            if valueIndices.count == 0 { continue }
                            let prevIndex = valueIndices[0]
                        } else {
                            prevIndex = 0
                        }
                        var cloned = m.clone()
                        try! cloned.insertAt(primaryChunkIndex, index: prevIndex!)
                        positionGuesses.insert(prevIndex!)
                        branches.append(cloned)
                    }
                } else {
                    // Determine the position of the removed chunk in relation to its changed entry value
                    for m in previousHistoryItemMimics {
                        let valueIndices = m.getIndicesOfValue(value: primaryChunkIndex)
                        if valueIndices.count == 0 { continue }
                        let removedIndex = valueIndices[0]
                        var cloned = m.clone()
                        try! cloned.removeAt(index: removedIndex)
                        positionGuesses.insert(removedIndex)
                        branches.append(cloned)
                    }
                }
                
                mimicLinkedListsForHistoryItems.append(branches)
            case .ADDITION_ON_NODE_VALUE:
                for m in previousHistoryItemMimics {
                    let mimicEstimatePositions: [Int] = m.getIndicesOfValue(value: h.atomicChanges[0].targetEntryIndex)
                    if mimicEstimatePositions.count != 0 {
                        positionGuesses.insert(mimicEstimatePositions.min()!)
                        positionGuesses.insert(mimicEstimatePositions.max()!)
                    }
                }
            }
        
            absolutePositionEstimateRangeForHistoryItems[i] = (positionGuesses.min() ?? -1, positionGuesses.max() ?? -1)
//            print(mimicLinkedListsForHistoryItems.last!)
            print("\(i): \(absolutePositionEstimateRangeForHistoryItems[i]!)")
        }
    }
    
    func decryptTLLDocument(doc: TLLEncryptedDocument, privateKey: PaillierScheme.PrivateKey) async throws -> [(BigInt, BigInt?)?] {
        var result: [(BigInt, BigInt?)?] = []
        let encValues = await doc.getEncryptedValues()
        
        for e in encValues {
            if let e {
                result.append((try privateKey.decrypt(encryptedNumber: e.0), e.1 != nil ? try privateKey.decrypt(encryptedNumber: e.1!) : nil))
            } else {
                result.append(nil)
            }
        }
        
        return result
    }
}

public enum TLLTestSuiteError: Error {
    case noHeadIndex
}
