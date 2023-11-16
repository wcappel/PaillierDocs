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
        print(self.knownHistory)
    }
    
    func decryptTLLDocument(doc: TLLEncryptedDocument, privateKey: PaillierScheme.PrivateKey) async throws -> [(BigInt, BigInt?)?] {
        var result: [(BigInt, BigInt?)?] = []
        let encValues = await doc.getEncryptedValues()
        
//        guard headIndex != nil else {
//            throw TLLTestSuiteError.noHeadIndex
//        }
//
//        var subsequent: BigInt? = try privateKey.decrypt(encryptedNumber: headIndex!)
//        while let currNext = subsequent {
//            let asInt: Int = Int(currNext.string())!
//            let entry = encValues[asInt]
//
//            if let entry {
//                result.append(try privateKey.decrypt(encryptedNumber: entry.0))
//                subsequent = entry.1 != nil ? try privateKey.decrypt(encryptedNumber: entry.1!) : nil
//            } else {
//                break
//            }
//        }
        
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


