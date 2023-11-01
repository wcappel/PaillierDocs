#!/usr/bin/swift

import Foundation
import Bignum

print("Started")

let (pubKey, privKey) = try PaillierScheme.generatePaillierKeypair()
var document = SLLEncryptedDocument(publicKey: pubKey)

var c0 = (pubKey.encrypt(plaintext: 5188146770730811392))
let o1 = SLLOperation(operationType: .INSERT_NEW_NODE, targetIndex: 0, localRevisionNum: 0, encryptedOperand: c0)

var c1 = pubKey.encrypt(plaintext: 576460752303423488)
let o2 = SLLOperation(operationType: .ADDITION_ON_NODE_VALUE, targetIndex: 0, localRevisionNum: 1, encryptedOperand: c1)

var c2 = pubKey.encrypt(plaintext: 144115188075855872)
let o3 = SLLOperation(operationType: .ADDITION_ON_NODE_VALUE, targetIndex: 0, localRevisionNum: 1, encryptedOperand: c2)


try await document.handleOperation(operation: o1)
print("O1: \(try await decryptDocument(doc: document, privateKey: privKey))")

try await document.handleOperation(operation: o2)
print("O2: \(try await decryptDocument(doc: document, privateKey: privKey))")

try await document.handleOperation(operation: o3)
print("O3: \(try await decryptDocument(doc: document, privateKey: privKey))")

//var c1 = (pubKey.encrypt(plaintext: 5188146770730811392)) // Add node w/ "H_______"
//c1.obfuscate()
//let o1 = SLLOperation(operationType: .INSERT_NEW_NODE, targetIndex: 0, localRevisionNum: 0, encryptedOperand: c1)
//try await document.handleOperation(operation: o1)
//print("O1: \(try await decryptDocument(doc: document, privateKey: privKey))")
//
//var c2 = pubKey.encrypt(plaintext: 28548185622315008) // Change node value to "Hello___"
//c2.obfuscate()
//let o2 = SLLOperation(operationType: .ADDITION_ON_NODE_VALUE, targetIndex: 0, localRevisionNum: 1, encryptedOperand: c2)
//try await document.handleOperation(operation: o2)
//print("O2: \(try await decryptDocument(doc: document, privateKey: privKey))")
//
//var c3 = pubKey.encrypt(plaintext: 0) // Add new zeroed node
//c3.obfuscate()
//let o3 = SLLOperation(operationType: .INSERT_NEW_NODE, targetIndex: 0, localRevisionNum: 2, encryptedOperand: c3)
//try await document.handleOperation(operation: o3)
//print("O3: \(try await decryptDocument(doc: document, privateKey: privKey))")
//
//var c4 = pubKey.encrypt(plaintext: 0) // Add new zeroed node
//c4.obfuscate()
//let o4 = SLLOperation(operationType: .INSERT_NEW_NODE, targetIndex: 1, localRevisionNum: 3, encryptedOperand: c4)
//try await document.handleOperation(operation: o4)
//print("O4: \(try await decryptDocument(doc: document, privateKey: privKey))")
//
//var c5 = pubKey.encrypt(plaintext: 8606223222788063232) // Lagging behind document by 1 revision, change node at index 1's value from 0 to world__
//c5.obfuscate()
//let o5 = SLLOperation(operationType: .ADDITION_ON_NODE_VALUE, targetIndex: 1, localRevisionNum: 3, encryptedOperand: c5)
//try await document.handleOperation(operation: o5) // Gets operationally transformed to affect intended node's new index
//print("O5: \(try await decryptDocument(doc: document, privateKey: privKey))")

//let str = "🌧⚡️asdfdsfas__한국어텍스트!!!ܐܣܛܪܢܓܠܐ ܐܠܦܒܝܬ"
//let encoded = str.toIntegerChunkEncoding()
//print(encoded)
//let decoded = encoded.fromIntegerChunkEncoding()
//print(decoded)

print("Done")


func decryptDocument(doc: SLLEncryptedDocument, privateKey: PaillierScheme.PrivateKey) async throws -> String {
    var result = ""
    let encValues = await document.getEncryptedValues()
    for c in encValues {
        let d = try privateKey.decrypt(encryptedNumber: c)
        result += "\(d) "
    }
    
    return result
}
