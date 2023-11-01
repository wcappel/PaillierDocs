//
//  TextToIntegerEncoding.swift
//  PaillierDocsProject
//
//  Created by Wilton Cappel on 11/1/23.
//

import Foundation
import Bignum

extension String {
    public func toIntegerChunkEncoding() -> [BigInt] {
        var chunkBinaryStrings: [String] = []
        var currChunkIndex = 0
        var currChunkRemainingBits = 64
        
        for u in self.utf8 {
            var asBinaryString = String(u, radix: 2)
            if asBinaryString.count % 8 == 7 {
                asBinaryString = "0" + asBinaryString
            }
            
            if !chunkBinaryStrings.indices.contains(currChunkIndex) {
                chunkBinaryStrings.append("")
            }
            
            if asBinaryString.count > currChunkRemainingBits && currChunkRemainingBits != 0 {
                // Split it between current and a new one
                let intoCurrent = asBinaryString[asBinaryString.startIndex...asBinaryString.index(asBinaryString.startIndex, offsetBy: currChunkRemainingBits - 1)]
                let intoNew = asBinaryString[asBinaryString.index(asBinaryString.startIndex, offsetBy: currChunkRemainingBits)..<asBinaryString.endIndex]
                
                chunkBinaryStrings[currChunkIndex] += intoCurrent
                
                chunkBinaryStrings.append("")
                currChunkIndex += 1
                chunkBinaryStrings[currChunkIndex] += intoNew
                currChunkRemainingBits = 64 - intoNew.count
            } else if currChunkRemainingBits == 0 {
                // Put all of it into a new one
                chunkBinaryStrings.append("")
                currChunkIndex += 1
                chunkBinaryStrings[currChunkIndex] += asBinaryString
                currChunkRemainingBits = 64 - asBinaryString.count
            } else {
                // Put it all into the current one
                chunkBinaryStrings[currChunkIndex] += asBinaryString
                currChunkRemainingBits -= asBinaryString.count
            }
        }
        
        while chunkBinaryStrings[chunkBinaryStrings.count - 1].count < 64 {
            // Add padding zeroes
            chunkBinaryStrings[chunkBinaryStrings.count - 1] += "0"
        }
        
        let asDecimalIntegers = chunkBinaryStrings.map { chunk in
            return BigInt(UInt(chunk, radix:2)!)
        }
        
        return asDecimalIntegers
    }
}

extension BigInt {
//    func fromIntegerChunkEncoding() -> String {
//
//    }
}
