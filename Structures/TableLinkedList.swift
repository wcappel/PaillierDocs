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
    private var entries: [NodeEntry<T>?]
    
    public init() {
        self.entries = []
    }
    
    public var size: Int {
        return entries.count
    }
    
    public mutating func addEntry(value: T, nextIndex: T) {
        let newEntry = NodeEntry(value: value, nextIndex: nextIndex)
        addToArrayInOut(newEntry, array: &self.entries)
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

