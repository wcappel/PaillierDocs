#!/usr/bin/swift

import BigNumber

print("Running")
assert(Utils.powMod(5, 3, 3) == 2)
assert(Utils.powMod(2, 10, 1000) == 24)

let p: BInt = 101
for i in 1...p-1 {
    let iinv = try! Utils.invert(i, p)
    print("iinv: \(iinv)")
    assert((iinv * i) % p == 1)
}
