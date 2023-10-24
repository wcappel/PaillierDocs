#!/usr/bin/swift

// Currently used for testing

import Foundation
import Bignum

print("Started")
let (pubKey, privKey) = try! PaillierScheme.generatePaillierKeypair()




print("Done")
