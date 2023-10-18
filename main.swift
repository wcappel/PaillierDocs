#!/usr/bin/swift

// Currently used for testing

import Foundation
import Bignum

print("Started")
let (pubKey, privKey): (PaillierScheme.PublicKey, PaillierScheme.PrivateKey) = try! PaillierScheme.generatePaillierKeypair()
let myVal: BigInt = 250
let myEncryptedVal = pubKey.encrypt(plaintext: myVal)
let myAddend: BigInt = 50
let myEncryptedAddend = pubKey.encrypt(plaintext: myAddend)
let myEncryptedResult = try! myEncryptedVal.add(other: myEncryptedAddend)
let myDecryptedResult = try! privKey.decrypt(encryptedNumber: myEncryptedResult)
print(myDecryptedResult)




print("Done")

//print("Running tests...")
//assert(Utils.powMod(5, 3, 3) == 2)
//assert(Utils.powMod(2, 10, 1000) == 24)
//
//let p: BInt = 101
//for i in 1...p-1 {
//    let iinv = try! Utils.invert(i, p)
//    print("iinv: \(iinv)")
//    assert((iinv * i) % p == 1)
//}
//
//let a: BInt = 3
//let q: BInt = 4
//assert((try! (a * Utils.invert(a, q)) %% q) == 1)
//
//assert([5, 7, 11, 13].contains(Utils.getPrimeOver(3)))
//
//for n: Int in 2...49 {
//    print(n)
//    let t = Utils.getPrimeOver(n)
//    assert(t >= 1 << (n-1))
//}

