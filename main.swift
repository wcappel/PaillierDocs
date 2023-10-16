#!/usr/bin/swift

// Currently used for testing

import BigNumber
import Foundation

print("Running")
assert(Utils.powMod(5, 3, 3) == 2)
assert(Utils.powMod(2, 10, 1000) == 24)

let p: BInt = 101
for i in 1...p-1 {
    let iinv = try! Utils.invert(i, p)
    print("iinv: \(iinv)")
    assert((iinv * i) % p == 1)
}

let a: BInt = 3
let q: BInt = 4
assert((try! (a * Utils.invert(a, q)) %% q) == 1)

assert([5, 7, 11, 13].contains(Utils.getPrimeOver(3)))

for n: Int in 2...49 {
    print(n)
    let t = Utils.getPrimeOver(n)
    assert(t >= 1 << (n-1))
}

//for i in 0...99 {
//    let n = Double.random(in: 2...10000000-1)
//    let nsq = n*n
//    assert(Int(floor((sqrt(n)))) == Int(Utils.iSqrt(BInt(n))))
//    print(Utils.iSqrt(BInt(nsq)))
//    print(BInt(1/n))
//    assert(Utils.iSqrt(BInt(nsq)) == BInt(1/n))
//}

