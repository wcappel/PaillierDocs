#!/usr/bin/swift

// Currently used for testing

import Foundation
import Bignum

print("Started")
let (pubKey, privKey) = try! PaillierScheme.generatePaillierKeypair()
let myVal: BigInt = 250
let myEncryptedVal = pubKey.encrypt(plaintext: myVal)
let myAddend: BigInt = 50
let myEncryptedAddend = pubKey.encrypt(plaintext: myAddend)
let myEncryptedResult = try! myEncryptedVal + myEncryptedAddend
let myDecryptedResult = try! privKey.decrypt(encryptedNumber: myEncryptedResult)
assert(myDecryptedResult == (myVal + myAddend))


var myList = SinglyLinkedList<PaillierScheme.EncryptedNumber>()
myList.append(myEncryptedVal)
try! myList.addAtIndex(addend: myEncryptedAddend, index: 0)
let encResult = try! myList.getAt(0)
let decResult = try! privKey.decrypt(encryptedNumber: encResult)
print(decResult)

print("Done")
