//
//  TableLinkedList.swift
//  
//
//  Created by Wilton Cappel on 10/20/23.
//

import Foundation

final private class NodeEntry<T> {
    var value: T
    var nextIndex: T?
    
    init(value: T, nextIndex: T?) {
        self.value = value
        self.nextIndex = nextIndex
    }
}

public struct TableLinkedList<T> {
    let INITIALIZED_NUM_OF_ENTRIES: Int = 10
    private var entries: [NodeEntry<T>?]
    // private var headIndex: T?
    
    // How will a user know where the head is?
    // Could we just use a property to track it?
    
    public init() {
        self.entries = []
        
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
        let newEntry = NodeEntry(value: value, nextIndex: nextIndex)
        
        for i in 0...self.entries.count - 1 {
            if self.entries[i] == nil {
                self.entries[i] = newEntry
                return
            }
        }
        
        self.doubleResize()
        self.entries[self.entries.count / 2] = newEntry
    }
    
    public mutating func addEntryAt(value: T, nextIndex: T?, at entryIndex: Int) throws {
        let newEntry = NodeEntry(value: value, nextIndex: nextIndex)
        
        guard entryIndex < self.entries.count else {
            throw LinkedListError.IndexOutOfRange
        }
        
        guard self.entries[entryIndex] == nil else {
            throw TableLLError.EntryIndexAlreadyOccupied
        }
        
        self.entries[entryIndex] = newEntry
    }
    
//    public mutating func changeHeadIndex(newHeadIndex: T) {
//        self.headIndex = newHeadIndex
//    }
    
    public mutating func removeEntry(at entryIndex: Int) throws {
        guard entryIndex < self.entries.count else {
            throw LinkedListError.IndexOutOfRange
        }
        
        self.entries[entryIndex] = nil
    }
    
    public func asTuples() -> [(T, T?)?] {
        return self.entries.map { entry -> (T, T?)? in
            if entry != nil {
                return (entry!.value, entry!.nextIndex)
            }
            
            return nil
        }
    }
    
//    public func getEncryptedHeadIndex() -> T? {
//        return self.headIndex
//    }
}

extension TableLinkedList where T: DefinedAdditiveOperation {
    public mutating func addToEntryValue(valueAddend: T, at entryIndex: Int) throws -> T {
        guard self.entries[entryIndex] != nil else {
            throw LinkedListError.IndexOutOfRange
        }
        
        self.entries[entryIndex]!.value = try self.entries[entryIndex]!.value + valueAddend
        
        return self.entries[entryIndex]!.value
    }
    
    public mutating func addToEntryNext(nextIndexAddend: T, at entryIndex: Int) throws -> T? {
        guard self.entries[entryIndex] != nil else {
            throw LinkedListError.IndexOutOfRange
        }
                
        self.entries[entryIndex]!.nextIndex = self.entries[entryIndex]!.nextIndex != nil ? try self.entries[entryIndex]!.nextIndex! + nextIndexAddend : nextIndexAddend
        
        return self.entries[entryIndex]!.nextIndex
    }
}


// Avoid CoW
public func addToArrayInOut<T: Any>(_ value: T, array: inout [T]) {
    array.append(value)
}

public enum TableLLError: Error {
    case EntryIndexAlreadyOccupied
}

