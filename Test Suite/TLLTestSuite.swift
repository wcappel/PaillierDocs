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
            try await self.showDocument()
        } catch {
            print(error)
        }
    }
    
    public func showDocument() async throws {
        let decrypted = try await decryptTLLDocument(doc: self.encryptedDoc, privateKey: self.privKey)
        var strResult = ""
        for d in decrypted {
            if let d, d.0 != 0 {
                let nextIndex = d.1 == -1 ? "X" : (d.1?.string(base: 10) ?? "NIL")
                strResult += "\t[\(String(bytes: d.0.fromSingleChunkEncoding(), encoding: .utf8)!), \(nextIndex)]\n"
            } else if let d, d.0 == 0 {
                let nextIndex = d.1 == -1 ? "X" : (d.1?.string(base: 10) ?? "NIL")
                strResult += "\t[\\0, \(nextIndex)]\n"
            } else {
                strResult += "\tNULL\n"
            }
        }
        
        print("DOCUMENT AT REVISION NUM: \(self.localRevisionNum)")
        print(strResult)
    }
    
    public func showHistory() {
        var strResult = ""
        for (i, h) in self.knownHistory.enumerated() {
            strResult += "\(i): \(h.operationType) — at \(h.atomicChanges[0].targetEntryIndex)"
            if h.atomicChanges.count == 2 {
                strResult += ", at \(h.atomicChanges[1].targetEntryIndex)"
            }
            strResult += "\n"
        }
        
        print(strResult)
    }
    
    public func trackHistoryAttempt() {
        var absolutePositionEstimateRangeForHistoryItems: [Int : (Int, Int)] = [:]
        var mimicLinkedListsForHistoryItems: [[SinglyLinkedList<Int>]] = [[]]
        
        for (i, h): (Int, TLLOperation) in self.knownHistory.enumerated() {
            if i == 0 {
                var startingMimic = SinglyLinkedList<Int>()
                startingMimic.append(0)
                absolutePositionEstimateRangeForHistoryItems[0] = (0, 0)
                mimicLinkedListsForHistoryItems.append([startingMimic])
                continue // Assume first operation is add
            }
            
            let previousHistoryItemMimics = mimicLinkedListsForHistoryItems.last!
            
            switch h.operationType {
            case .INSERT_OR_DELETE_NODE:
                <#code#>
            case .ADDITION_ON_NODE_VALUE:
                var positionGuesses: Set<Int> = Set<Int>()
                for m in previousHistoryItemMimics {
                    let mimicEstimatePositions: [Int] = m.getIndicesOfValue(value: h.atomicChanges[0].targetEntryIndex)
                    if mimicEstimatePositions.count != 0 {
                        positionGuesses.insert(mimicEstimatePositions.min()!)
                        positionGuesses.insert(mimicEstimatePositions.max()!)
                    }
                }
                
                absolutePositionEstimateRangeForHistoryItems[i] = (positionGuesses.min() ?? -1, positionGuesses.max() ?? -1)
            }
        }
        
        /*
            ADD - 3 operations: addition on prev entry's next value, addition on new entry's c value, and addition on new entry's next value
                - Edge case of adding first node: No prev entry next value additon
            REMOVE - 3 operations: addition on prev entry's next value, addition on removed entry's c value, addition on removed entry's next value
                - Edge case of removing first node: No prev entry next value addition
            EDIT - 1 operation: addition on entry's c value; can always be masked as an ADD/REMOVE
         
            The only thing that can distinguish a remove from an add is if the server knows the changed next value for the previous entry was on a previously added node
            The only thing that can distinguish a add from a remove is if the server knows that the newly added entry has never been touched, or was previously removed
            The first operation can always assumed to be an add (unless it's fake)
         */
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


