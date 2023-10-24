//
//  IndexedLinkedList.swift
//  
//
//  Created by Wilton Cappel on 10/20/23.
//

import Foundation

final private class IndexedNode<T> {
    var value: T
    var nextIndex: T
    
    init(value: T, nextIndex: T) {
        self.value = value
        self.nextIndex = nextIndex
    }
}

public struct IndexedLinkedList<T> {
    let INITIALIZED_NUM_OF_ENTRIES: Int = 100
    private var entries: [IndexedNode<T>?]
    // Put revision # in actor/object handling operational transforms
    private(set) var numOfEdits: Int
    
    // How will a user know where the head is?
    // Could we just use a property to track it?
    
    public init() {
        self.entries = []
        self.numOfEdits = 0
        
        for _ in 0...INITIALIZED_NUM_OF_ENTRIES - 1 {
            addToArrayInOut(nil, array: &self.entries)
        }
    }
    
    private mutating func doubleResize() {
        assert(self.entries.count > 0)
        for _ in 0...self.entries.count - 1 {
            addToArrayInOut(nil, array: &self.entries)
        }
    }
    
    public mutating func addEntry(value: T, nextIndex: T) {
        let newEntry = IndexedNode(value: value, nextIndex: nextIndex)
        
        defer {
            self.numOfEdits += 1
        }
        
        for i in 0...self.entries.count - 1 {
            if self.entries[i] == nil {
                self.entries[i] = newEntry
                return
            }
        }
        
        self.doubleResize()
        self.entries[self.entries.count / 2] = newEntry
    }
    
    public mutating func addEntryAt(value: T, nextIndex: T, at entryIndex: Int) throws {
        let newEntry = IndexedNode(value: value, nextIndex: nextIndex)
        
        guard entryIndex < self.entries.count else {
            throw LinkedListError.IndexOutOfRange
        }
        
        guard self.entries[entryIndex] == nil else {
            throw IndexedLLError.EntryIndexAlreadyOccupied
        }
        
        self.entries[entryIndex] = newEntry
        self.numOfEdits += 1
    }
    
    public mutating func removeEntry(at entryIndex: Int) throws {
        guard entryIndex < self.entries.count else {
            throw LinkedListError.IndexOutOfRange
        }
        
        self.entries[entryIndex] = nil
        
        self.numOfEdits += 1
    }
    
    public func asTuples() -> [(T, T)?] {
        return self.entries.map { entry -> (T, T)? in
            if entry != nil {
                return (entry!.value, entry!.nextIndex)
            }
            
            return nil
        }
    }
}

extension IndexedLinkedList where T: DefinedAdditiveOperation {
    public mutating func addToEntry(valueAddend: T, nextIndexAddend: T, at entryIndex: Int) throws -> (T, T) {
        guard self.entries[entryIndex] != nil else {
            throw LinkedListError.IndexOutOfRange
        }
        
        self.entries[entryIndex]!.value = try self.entries[entryIndex]!.value + valueAddend
        self.entries[entryIndex]!.nextIndex = try self.entries[entryIndex]!.nextIndex + nextIndexAddend
        
        self.numOfEdits += 1
        return (self.entries[entryIndex]!.value, self.entries[entryIndex]!.nextIndex)
    }
}


// Avoid CoW
public func addToArrayInOut<T: Any>(_ value: T, array: inout [T]) {
    array.append(value)
}

public enum IndexedLLError: Error {
    case EntryIndexAlreadyOccupied
}

