//
//  Paillier.swift
//
//  This is essentially a Swift
//  adaptation/copy of the python-paillier
//  library at: https://github.com/data61/python-paillier
//  Will eventually add their notice/license as I've
//  just translated their code into a different language
//  with Swift-BigInt for handling nums

import Foundation
import BigNumber

struct PaillierScheme {
    static let DEFAULT_KEYSIZE = 3072
    
    public static func generatePaillierKeypair(nLength: Int = DEFAULT_KEYSIZE)
    throws -> (PublicKey, PrivateKey) {
        var nLen = 0
        var n: BInt = 0
        
        while nLen != nLength {
            let p = Utils.getPrimeOver(nLength / 2)
            var q = p
            while q == p {
                q = Utils.getPrimeOver(nLength / 2)
            }
            n = p * q
            nLen = n.bitWidth
        }
        
        let publicKey = PublicKey(n: n)
        let privateKey = try? PrivateKey(publicKey: publicKey, p: p, q: q)
        
        guard let privateKey else {
            throw PaillierSchemeError.InvalidKeySize
        }
        
        return (publicKey, privateKey)
    }
    
    struct EncryptedNumber {
        let publicKey: PublicKey
        private let ciphertext: BInt
        private var isObfuscated: Bool
        
        public init(publicKey: PublicKey, ciphertext: BInt) {
            self.publicKey = publicKey
            self.ciphertext = ciphertext
            self.isObfuscated = false
        }
        
        public func obfuscate() {
            // TO-DO
        }
        
        public func ciphertext(secure: Bool) -> BInt {
            if secure && !self.isObfuscated {
                self.obfuscate()
            }
            
            return self.ciphertext
        }
        
        private func rawAdd(c1: BInt, c2: BInt) -> BInt {
            return Utils.mulMod(c1, c2, self.publicKey.nSquare)
        }
        
        public func add(other: EncryptedNumber) throws -> EncryptedNumber {
            guard self.publicKey == other.publicKey else {
                throw PaillierSchemeError.DifferentPublicKeys
            }
            
            let (a, b) = (self, other)
            
            let sum = a.rawAdd(
                c1: a.ciphertext(secure: false),
                c2: b.ciphertext(secure: false)
            )
            
            return EncryptedNumber(publicKey: a.publicKey, ciphertext: sum)
        }
    }
    
    struct PublicKey: Equatable {
        let g: BInt
        let n: BInt
        let nSquare: BInt
        let maxInt: BInt
        
        init(n: BInt) {
            self.g = n + 1
            self.n = n
            self.nSquare = n * n
            self.maxInt = n / 3 - 1
        }
        
        private func rawEncrypt(plaintext: BInt) -> BInt {
            let nudeCiphertext = (self.n * plaintext + 1) %% self.nSquare
            
            let r = self.getRandomLtN()
            let obfuscator = Utils.powMod(r, self.n, self.nSquare)
            
            return Utils.mulMod(nudeCiphertext, obfuscator, self.nSquare)
        }
        
        public func encrypt(plaintext: BInt) -> EncryptedNumber {
            return EncryptedNumber(
                publicKey: self,
                ciphertext: self.rawEncrypt(plaintext: plaintext)
            )
        }
        
        private func getRandomLtN() -> BInt {
            let range = self.n <= UInt64.max ? 1...UInt64.max : 1...UInt64(self.n)
            return BInt(UInt64.random(in: range))
        }
    }
    
    struct PrivateKey {
        public let publicKey: PublicKey
        let p: BInt
        let q: BInt
        let pSquare: BInt
        let qSquare: BInt
        let pInverse: BInt
        let hp: BInt
        let hq: BInt
        
        init(publicKey: PublicKey, p: BInt, q: BInt) throws {
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
            self.pInverse = try Utils.invert(self.p, self.q)
            
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
        }
        
        private func rawDecrypt(ciphertext: BInt) -> BInt {
            let decryptToP = Utils.mulMod(
                PrivateKey.lFunc(Utils.powMod(ciphertext, self.p - 1, self.pSquare), self.p),
                self.hp,
                self.p
            )
            let decryptToQ = Utils.mulMod(
                PrivateKey.lFunc(Utils.powMod(ciphertext, self.q - 1, self.qSquare), self.q),
                self.hq,
                self.q
            )
            
            return self.crt(mp: decryptToP, mq: decryptToQ)
        }
        
        public func decrypt(encryptedNumber: EncryptedNumber) throws -> BInt {
            guard self.publicKey == encryptedNumber.publicKey else {
                throw PaillierSchemeError.DifferentPublicKeys
            }
            
            return self.rawDecrypt(ciphertext: encryptedNumber.ciphertext(secure: false))
        }
        
        static func hFunc(_ x: BInt, _ xsquare: BInt, publicKey: PublicKey) throws -> BInt {
            return try Utils.invert(self.lFunc(Utils.powMod(publicKey.g, x - 1, xsquare),x), x)
        }

        static func lFunc(_ x: BInt, _ p: BInt) -> BInt {
            return (x - 1) / p
        }
        
        func crt(mp: BInt, mq: BInt) -> BInt {
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
