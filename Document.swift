//
//  File.swift
//  PaillierDocsProject
//
//  Created by Wilton Cappel on 10/23/23.
//

import Foundation

actor DocumentController {
    private let publicKey: PaillierScheme.PublicKey
    private var textStructure: SinglyLinkedList<PaillierScheme.EncryptedNumber>
    private var revisionNum: Int
    // And some object here to store session history for OT
    
    init(publicKey: PaillierScheme.PublicKey) {
        self.publicKey = publicKey
        self.textStructure = SinglyLinkedList()
        self.revisionNum = 0
    }
    
    
}

