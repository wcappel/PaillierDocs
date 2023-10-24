//
//  SinglyLinkedList.swift
//  PaillierDocsProject
//
//  Created by Wilton Cappel on 10/19/23.
//

import Foundation

final private class SinglyLinkedNode<T> {
    var value: T
    var next: SinglyLinkedNode<T>?
    
    init(value: T) {
        self.value = value
        self.next = nil
    }
}

public struct SinglyLinkedList<T> {
    private var head: SinglyLinkedNode<T>?
    private var tail: SinglyLinkedNode<T>?
    private(set) var size: Int
    
    public init() {
        self.size = 0
        self.head = nil
        self.tail = nil
    }
    
    public mutating func append(_ value: T) {
        let newNode: SinglyLinkedNode<T> = SinglyLinkedNode(value: value)
        
        defer {
            self.size += 1
        }
        
        if self.head == nil && self.tail == nil {
            self.head = newNode
            self.tail = newNode
            return
        }
        
        if var currNode = self.head {
            while currNode.next != nil {
                currNode = currNode.next!
            }
            
            currNode.next = newNode
            self.tail = newNode
        }
    }
    
    public mutating func prepend(_ value: T) {
        let newNode: SinglyLinkedNode<T> = SinglyLinkedNode(value: value)
        
        defer {
            self.size += 1
        }
        
        self.head = newNode
        if tail == nil {
            self.tail = newNode
        }
    }
    
    private func nodeAt(_ index: Int) -> SinglyLinkedNode<T>? {
        var currIndex = 0
        var currNode = self.head
        
        while currNode != nil && currIndex < index {
            currNode = currNode!.next
            currIndex += 1
        }
        
        return currNode
    }
    
    public func getAt(_ index: Int) throws -> T {
        guard let result = nodeAt(index) else {
            throw LinkedListError.IndexOutOfRange
        }
        
        return result.value
    }
    
    public func first() throws -> T {
        guard let head = self.head else {
            throw LinkedListError.EmptyList
        }
        
        return head.value
    }
    
    public func last() throws -> T {
        guard let tail = self.tail else {
            throw LinkedListError.EmptyList
        }
        
        return tail.value
    }
    
    public mutating func insertAfter(_ value: T, index: Int) throws {
        let newNode: SinglyLinkedNode<T> = SinglyLinkedNode(value: value)
        
        if self.head == nil && index == 0 {
            self.append(value)
            return
        }
        
        
        guard let nodeAtIndex = nodeAt(index) else {
            throw LinkedListError.IndexOutOfRange
        }
        
        if nodeAtIndex.next == nil {
            nodeAtIndex.next = newNode
            self.tail = newNode
        } else {
            newNode.next = nodeAtIndex.next
            nodeAtIndex.next = newNode
        }
        
        self.size += 1
    }
    
    public mutating func removeFirst() throws {
        guard self.head != nil else {
            throw LinkedListError.EmptyList
        }
        
        self.head = self.head!.next
        self.size -= 1
    }
    
    public mutating func removeLast() throws {
        guard self.head != nil else {
            throw LinkedListError.EmptyList
        }
        
        if self.head!.next == nil {
            try self.removeFirst()
            return
        }
        
        var currNode = self.head!
        var prevNode = self.head!
        
        while let next = currNode.next {
            prevNode = currNode
            currNode = next
        }
        
        prevNode.next = nil
        self.tail = prevNode
        self.size -= 1
    }
    
    public mutating func removeAt(index: Int) throws {
        guard self.head != nil else {
            throw LinkedListError.EmptyList
        }
        
        if index == 0 {
            try self.removeFirst()
            return
        }
        
        if index == self.size - 1 {
            try self.removeLast()
            return
        }
        
        if let prevNode = self.nodeAt(index - 1) {
            prevNode.next = prevNode.next!.next
            
            self.size -= 1
            return
        }
        
        throw LinkedListError.IndexOutOfRange
    }
    
    public func describe() {
        var str = ""
        if var currNode = self.head {
            str += "<\(currNode.value)>"
            while currNode.next != nil {
                str += "<\(currNode.next!.value)>"
                currNode = currNode.next!
            }
            
            print(str)
            return
        }
        
        print("<Empty>")
    }
    
    public func asArray() -> [T] {
        var result: [T] = []
        if var currNode = self.head {
            result.append(currNode.value)
            while currNode.next != nil {
                result.append(currNode.next!.value)
                currNode = currNode.next!
            }
        }
        return result
    }
}

public protocol DefinedAdditiveOperation {
    static func +(lhs: Self, rhs: Self) throws -> Self
}

extension SinglyLinkedList where T: DefinedAdditiveOperation {
    public func addAtIndex(addend: T, index: Int) throws -> T {
        guard let nodeAtIndex = self.nodeAt(index) else {
            throw LinkedListError.IndexOutOfRange
        }
        
        nodeAtIndex.value = try nodeAtIndex.value + addend
        return nodeAtIndex.value
    }
}

enum LinkedListError: Error {
    case IndexOutOfRange
    case EmptyList
}
