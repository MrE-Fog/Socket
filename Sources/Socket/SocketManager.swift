//
//  SocketManager.swift
//  
//
//  Created by Alsey Coleman Miller on 4/1/22.
//

import Foundation
import SystemPackage

/// Socket Manager
public protocol SocketManager: AnyObject {
    
    /// Add file descriptor
    func add(
        _ fileDescriptor: SocketDescriptor
    ) async
    
    /// Remove file descriptor
    func remove(
        _ fileDescriptor: SocketDescriptor,
        error: Error?
    ) async
    
    /// Wait for events.
    func wait(
        for event: FileEvents,
        fileDescriptor: SocketDescriptor
    ) async throws
    
    /// Write data to managed file descriptor.
    func write(
        _ data: Data,
        for fileDescriptor: SocketDescriptor
    ) async throws -> Int
    
    /// Read managed file descriptor.
    func read(
        _ length: Int,
        for fileDescriptor: SocketDescriptor
    ) async throws -> Data
    
    func receiveMessage(
        _ length: Int,
        for fileDescriptor: SocketDescriptor
    ) async throws -> Data
    
    func receiveMessage<Address: SocketAddress>(
        _ length: Int,
        fromAddressOf addressType: Address.Type,
        for fileDescriptor: SocketDescriptor
    ) async throws -> (Data, Address)
    
    func sendMessage(
        _ data: Data,
        for fileDescriptor: SocketDescriptor
    ) async throws -> Int
    
    func sendMessage<Address: SocketAddress>(
        _ data: Data,
        to address: Address,
        for fileDescriptor: SocketDescriptor
    ) async throws -> Int
    
    /// Accept new socket.
    func accept(
        for fileDescriptor: SocketDescriptor
    ) async throws -> SocketDescriptor
    
    /// Accept a connection on a socket.
    func accept<Address: SocketAddress>(
        _ address: Address.Type,
        for fileDescriptor: SocketDescriptor
    ) async throws -> (fileDescriptor: SocketDescriptor, address: Address)
    
    /// Initiate a connection on a socket.
    func connect<Address: SocketAddress>(
        to address: Address,
        for fileDescriptor: SocketDescriptor
    ) async throws
}

public extension SocketManager {
    
    /// Write data to managed file descriptor.
    func write(
        _ data: Data,
        for fileDescriptor: SocketDescriptor
    ) async throws -> Int {
        try await wait(for: .write, fileDescriptor: fileDescriptor)
        let byteCount = try data.withUnsafeBytes {
            try fileDescriptor.write($0)
        }
        return byteCount
    }
    
    /// Read managed file descriptor.
    func read(
        _ length: Int,
        for fileDescriptor: SocketDescriptor
    ) async throws -> Data {
        try await wait(for: .read, fileDescriptor: fileDescriptor)
        var data = Data(count: length)
        let bytesRead = try data.withUnsafeMutableBytes {
            try fileDescriptor.read(into: $0)
        }
        if bytesRead < length {
            data = data.prefix(bytesRead)
        }
        return data
    }
    
    func sendMessage(
        _ data: Data,
        for fileDescriptor: SocketDescriptor
    ) async throws -> Int {
        try await wait(for: .write, fileDescriptor: fileDescriptor)
        let byteCount = try data.withUnsafeBytes {
            try fileDescriptor.send($0)
        }
        return byteCount
    }
    
    func sendMessage<Address: SocketAddress>(
        _ data: Data,
        to address: Address,
        for fileDescriptor: SocketDescriptor
    ) async throws -> Int {
        try await wait(for: .write, fileDescriptor: fileDescriptor)
        let byteCount = try data.withUnsafeBytes {
            try fileDescriptor.send($0, to: address)
        }
        return byteCount
    }
    
    func receiveMessage(
        _ length: Int,
        for fileDescriptor: SocketDescriptor
    ) async throws -> Data {
        try await wait(for: .read, fileDescriptor: fileDescriptor)
        var data = Data(count: length)
        let bytesRead = try data.withUnsafeMutableBytes {
            try fileDescriptor.receive(into: $0)
        }
        if bytesRead < length {
            data = data.prefix(bytesRead)
        }
        return data
    }
    
    func receiveMessage<Address: SocketAddress>(
        _ length: Int,
        fromAddressOf addressType: Address.Type,
        for fileDescriptor: SocketDescriptor
    ) async throws -> (Data, Address) {
        try await wait(for: .read, fileDescriptor: fileDescriptor)
        var data = Data(count: length)
        let (bytesRead, address) = try data.withUnsafeMutableBytes {
            try fileDescriptor.receive(into: $0, fromAddressOf: addressType)
        }
        if bytesRead < length {
            data = data.prefix(bytesRead)
        }
        return (data, address)
    }
    
    /// Accept a connection on a socket.
    func accept(for fileDescriptor: SocketDescriptor) async throws -> SocketDescriptor {
        try await wait(for: [.read, .write], fileDescriptor: fileDescriptor)
        return try fileDescriptor.accept()
    }
    
    /// Accept a connection on a socket.
    func accept<Address: SocketAddress>(
        _ address: Address.Type,
        for fileDescriptor: SocketDescriptor
    ) async throws -> (fileDescriptor: SocketDescriptor, address: Address) {
        try await wait(for: [.read, .write], fileDescriptor: fileDescriptor)
        return try fileDescriptor.accept(address)
    }
    
    /// Initiate a connection on a socket.
    func connect<Address: SocketAddress>(
        to address: Address,
        for fileDescriptor: SocketDescriptor
    ) async throws {
        try await wait(for: [.write], fileDescriptor: fileDescriptor)
        try fileDescriptor.connect(to: address)
    }
}

/// Socket Manager Configuration
public protocol SocketManagerConfiguration {
    
    associatedtype Manager: SocketManager
    
    /// Manager
    static var manager: Manager { get }
    
    func configureManager()
}
