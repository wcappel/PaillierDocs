#!/usr/bin/swift

import Foundation
import Bignum

print("Started")

let (pubKey, privKey) = try PaillierScheme.generatePaillierKeypair()

var document = ILLEncryptedDocument(publicKey: pubKey)
var testSuite = ILLTestSuite(doc: document, privKey: privKey)






//var document = SLLEncryptedDocument(publicKey: pubKey)
//
//var c1 = pubKey.encrypt(plaintext:"Paillier".toIntegerChunkEncoding()[0])
//c1.obfuscate()
//let o1 = SLLOperation(operationType: .INSERT_NEW_NODE, targetIndex: 0, localRevisionNum: 0, encryptedOperand: c1)
//try await document.handleOperation(operation: o1)
//print("O1: \((try await decryptSLLDocument(doc: document, privateKey: privKey)).fromIntegerChunkEncoding())")
//
//var c2a = pubKey.encrypt(plaintext: "Paulluer".toIntegerChunkEncoding()[0] - "Paillier".toIntegerChunkEncoding()[0])
//c2a.obfuscate()
//let o2a = SLLOperation(operationType: .ADDITION_ON_NODE_VALUE, targetIndex: 0, localRevisionNum: 1, encryptedOperand: c2a)
//var c2b = pubKey.encrypt(plaintext: "Railliex".toIntegerChunkEncoding()[0] - "Paillier".toIntegerChunkEncoding()[0])
//c2b.obfuscate()
//let o2b = SLLOperation(operationType: .ADDITION_ON_NODE_VALUE, targetIndex: 0, localRevisionNum: 1, encryptedOperand: c2b)
//try await document.handleOperation(operation: o2a)
//print("O2a: \((try await decryptSLLDocument(doc: document, privateKey: privKey)).fromIntegerChunkEncoding())")
//try await document.handleOperation(operation: o2b)
//print("O2b: \((try await decryptSLLDocument(doc: document, privateKey: privKey)).fromIntegerChunkEncoding())")

print("Done")


func decryptSLLDocument(doc: SLLEncryptedDocument, privateKey: PaillierScheme.PrivateKey) async throws -> [BigInt] {
    var result: [BigInt] = []
    let encValues = await doc.getEncryptedValues()
    for c in encValues {
        let d = try privateKey.decrypt(encryptedNumber: c)
        result.append(d)
    }
    
    return result
}
