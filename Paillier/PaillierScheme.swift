//
//  PaillierScheme.swift
//
//  This is essentially a Swift
//  adaptation/copy of the python-paillier
//  library at: https://github.com/data61/python-paillier
//  Will eventually add their notice/license as I've
//  just translated their code into a different language
//  with the Bignum GMP wrapper for handling nums

import Foundation
import Bignum

struct PaillierScheme {
    static let DEFAULT_KEYSIZE: UInt = 3072
    
    public static func generatePaillierKeypair(nLength: UInt = DEFAULT_KEYSIZE)
    throws -> (PublicKey, PrivateKey) {
        var nLen = 0
        var n: BigInt = 0
        var q: BigInt = 0
        var p: BigInt = 0
        
        while nLen != nLength {
            p = Utils.getPrimeOver(nLength / 2)
            q = p
            while q == p {
                q = Utils.getPrimeOver(nLength / 2)
            }
            n = p * q
            nLen = n.bitSize()
        }
        
        let publicKey = PublicKey(n: n)
        print("Created public key")
        let privateKey = try? PrivateKey(publicKey: publicKey, p: p, q: q)
        
        guard let privateKey else {
            throw PaillierSchemeError.InvalidKeySize
        }
        
        return (publicKey, privateKey)
    }
    
    struct EncryptedNumber {
        let publicKey: PublicKey
        private(set) var ciphertext: BigInt
        private(set) var isObfuscated: Bool
        
        public init(publicKey: PublicKey, ciphertext: BigInt) {
            self.publicKey = publicKey
            self.ciphertext = ciphertext
            self.isObfuscated = false
        }
        
        public mutating func obfuscate() {
            let r = self.publicKey.getRandomNumLessThanN()
            let rPowN = mod_exp(r, self.publicKey.n, self.publicKey.nSquare)
            self.ciphertext = Utils.mulMod(self.ciphertext, rPowN, self.publicKey.nSquare)
            self.isObfuscated = true
        }
        
        private func rawAdd(c1: BigInt, c2: BigInt) -> BigInt {
            return Utils.mulMod(c1, c2, self.publicKey.nSquare)
        }
        
        public func add(other: EncryptedNumber) throws -> EncryptedNumber {
            guard self.publicKey == other.publicKey else {
                throw PaillierSchemeError.DifferentPublicKeys
            }
            
            let (a, b) = (self, other)
            
            let sum = a.rawAdd(
                c1: a.ciphertext,
                c2: b.ciphertext
            )
            
            return EncryptedNumber(publicKey: a.publicKey, ciphertext: sum)
        }
        
        static func +(lhs: PaillierScheme.EncryptedNumber, rhs: PaillierScheme.EncryptedNumber)
        throws -> PaillierScheme.EncryptedNumber {
            return try lhs.add(other: rhs)
        }

    }
    
    struct PublicKey: Equatable {
        let g: BigInt
        let n: BigInt
        let nSquare: BigInt
        let maxInt: BigInt
        
        init(n: BigInt) {
            self.g = n + 1
            self.n = n
            self.nSquare = n * n
            self.maxInt = n / 3 - 1
        }
        
        private func rawEncrypt(plaintext: BigInt) -> BigInt {
            let nudeCiphertext = (self.n * plaintext + 1) %% self.nSquare
            
            let r = self.getRandomNumLessThanN()
            let obfuscator = mod_exp(r, self.n, self.nSquare)
            
            return Utils.mulMod(nudeCiphertext, obfuscator, self.nSquare)
        }
        
        public func encrypt(plaintext: BigInt) -> EncryptedNumber {
            return EncryptedNumber(
                publicKey: self,
                ciphertext: self.rawEncrypt(plaintext: plaintext)
            )
        }
        
        func getRandomNumLessThanN() -> BigInt {
            return BigInt.randomInt(limit: self.n)
        }
    }
    
    struct PrivateKey {
        public let publicKey: PublicKey
        let p: BigInt
        let q: BigInt
        let pSquare: BigInt
        let qSquare: BigInt
        let pInverse: BigInt
        let hp: BigInt
        let hq: BigInt
        
        init(publicKey: PublicKey, p: BigInt, q: BigInt) throws {
            if publicKey.n != p * q {
                throw PaillierSchemeError.InvalidPublicKey
            }
            
            if p == q {
                throw PaillierSchemeError.pqValuesSame
            }
            
            self.publicKey = publicKey
            
            if q < p {
                self.p = q
                self.q = p
            } else {
                self.p = p
                self.q = q
            }
            
            self.pSquare = self.p * self.p
            self.qSquare = self.q * self.q
            self.pInverse = inverse(self.p, self.q)!
            
            self.hp = try PaillierScheme.PrivateKey.hFunc(
                self.p,
                self.pSquare,
                publicKey: self.publicKey
            )
            
            self.hq = try PaillierScheme.PrivateKey.hFunc(
                self.q,
                self.qSquare,
                publicKey: self.publicKey
            )
            print("Created private key")
        }
        
        private func rawDecrypt(ciphertext: BigInt) -> BigInt {
            let decryptToP = Utils.mulMod(
                PrivateKey.lFunc(mod_exp(ciphertext, self.p - 1, self.pSquare), self.p),
                self.hp,
                self.p
            )
            let decryptToQ = Utils.mulMod(
                PrivateKey.lFunc(mod_exp(ciphertext, self.q - 1, self.qSquare), self.q),
                self.hq,
                self.q
            )
            
            return self.crt(mp: decryptToP, mq: decryptToQ)
        }
        
        public func decrypt(encryptedNumber: EncryptedNumber) throws -> BigInt {
            guard self.publicKey == encryptedNumber.publicKey else {
                throw PaillierSchemeError.DifferentPublicKeys
            }
            
            return self.rawDecrypt(ciphertext: encryptedNumber.ciphertext)
        }
        
        static func hFunc(_ x: BigInt, _ xsquare: BigInt, publicKey: PublicKey) throws -> BigInt {
            return inverse(self.lFunc(mod_exp(publicKey.g, x - 1, xsquare),x), x)!
        }

        static func lFunc(_ x: BigInt, _ p: BigInt) -> BigInt {
            return (x - 1) / p
        }
        
        func crt(mp: BigInt, mq: BigInt) -> BigInt {
            let u = Utils.mulMod(mq - mp, self.pInverse, self.q)
            return mp + (u * self.p)
        }
    }
}

enum PaillierSchemeError: Error {
    case InvalidPublicKey
    case pqValuesSame
    case DifferentPublicKeys
    case InvalidKeySize
}
