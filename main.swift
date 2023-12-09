#!/usr/bin/swift

import Foundation
import Bignum

print("Started")

let (pubKey, privKey) = try PaillierScheme.generatePaillierKeypair()
let clock = ContinuousClock()

print("------------------- BENCHMARKING -------------------")
print("Benchmarking - Encryption")
var encTimes: [Duration] = []
for _ in 1...100 {
    let elapsed = clock.measure {
        pubKey.encrypt(plaintext: BigInt.randomInt(bits: 64))
    }

    encTimes.append(elapsed)
}
var encResultSum: Duration = .seconds(0)
print("\tRESULTS: \(encTimes.reduce(encResultSum, +) / encTimes.count) on average")

print("Benchmarking - Decryption")
var decTimes: [Duration] = []
for _ in 1...100 {
    let c = pubKey.encrypt(plaintext: BigInt.randomInt(bits: 64))
    let elapsed = clock.measure {
        try? privKey.decrypt(encryptedNumber: c)
    }

    decTimes.append(elapsed)
}
var decResultSum: Duration = .seconds(0)
print("\tRESULTS: \(decTimes.reduce(decResultSum, +) / decTimes.count) on average")

print("Benchmarking - Homomorphic Addition")
var addTimes: [Duration] = []
for _ in 1...100 {
    let c1 = pubKey.encrypt(plaintext: BigInt.randomInt(bits: 31))
    let c2 = pubKey.encrypt(plaintext: BigInt.randomInt(bits: 31))
    let elapsed = clock.measure {
        try? c1 + c2
    }

    addTimes.append(elapsed)
}
var addResultSum: Duration = .seconds(0)
print("\tRESULTS: \(addTimes.reduce(addResultSum, +) / addTimes.count) on average")

print("-------------------- TEST SUITE --------------------")

var document = TLLEncryptedDocument(publicKey: pubKey)
var testSuite = TLLTestSuite(doc: document, privKey: privKey)

await testSuite.scenario_straightAppendsWithEdits(fakeOperations: true)

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
