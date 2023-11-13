//
//  ILLTestSuite.swift
//  
//
//  Created by Wilton Cappel on 11/10/23.
//

import Foundation
import Bignum

class ILLTestSuite {
    private var encryptedDoc: ILLEncryptedDocument
    private let privKey: PaillierScheme.PrivateKey
    private var localRevisionNum: Int
    private var knownHistory: [ILLOperation]
    
    public init(doc: ILLEncryptedDocument, privKey: PaillierScheme.PrivateKey) {
        self.encryptedDoc = doc
        self.privKey = privKey
        self.localRevisionNum = 0
        self.knownHistory = []
    }
    
    public func perform(operation: ILLOperation, laggingBy: Int = 0) async {
        assert(laggingBy >= 0)
        do {
            try await encryptedDoc.handleOperation(operation: operation)
            knownHistory.append(operation)
            try await self.showDocument()
        } catch {
            print(error)
        }
    }
    
    public func showDocument() async throws {
        let decrypted = try await decryptILLDocument(doc: self.encryptedDoc, privateKey: self.privKey)
        var strResult = ""
        for d in decrypted {
            if let d {
                strResult += "\t[\(String(bytes: d.0.fromSingleChunkEncoding(), encoding: .utf8)!), \(d.1)]\n"
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
    
    func decryptILLDocument(doc: ILLEncryptedDocument, privateKey: PaillierScheme.PrivateKey) async throws -> [(BigInt, BigInt?)?] {
        var result: [(BigInt, BigInt?)?] = []
        let encValues = await doc.getEncryptedValues()
        
//        guard headIndex != nil else {
//            throw ILLTestSuiteError.noHeadIndex
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

public enum ILLTestSuiteError: Error {
    case noHeadIndex
}


