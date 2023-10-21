//
//  PaillierUtils.swift
//
//  This is essentially a Swift
//  adaptation/copy of the python-paillier
//  library at: https://github.com/data61/python-paillier
//  Will eventually add their notice/license as I've
//  just translated their code into a different language
//  with the Bignum GMP wrapper for handling nums

import Foundation
import Bignum

infix operator %%
// Swift's % is not true modulo
public func %%(lhs: BigInt, rhs: BigInt) -> BigInt {
    assert(rhs > 0)
    let r = lhs % rhs
    
    return r >= 0 ? r : r + rhs
}

struct Utils {
    @inlinable static func mulMod(_ a: BigInt, _ b: BigInt, _ c: BigInt) -> BigInt {
        return (a * b) %% c
    }
    
    @inlinable static func getPrimeOver(_ N: UInt) -> BigInt {
        let n: BigInt = BigInt.randomInt(bits: N)
        let res = BigInt.nextPrime(n)
        return res
    }
}

enum PaillierUtilsError: Error {
    case ZeroDivisionError
}
