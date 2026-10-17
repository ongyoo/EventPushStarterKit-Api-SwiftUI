//
//  ContainerTests.swift
//  EventPushStarterKit
//
//  Created by Komsit Chusangthong on 16/10/2569 BE.
//

@testable import Core
import Testing

private protocol Greeter: Sendable { func greet() -> String }
private struct EnglishGreeter: Greeter { func greet() -> String { "Hello" } }
private struct ThaiGreeter: Greeter { func greet() -> String { "สวัสดี" } }
private final class Counter: @unchecked Sendable {}

private extension Container {
    var greeter: Dependency<any Greeter> { Dependency(self) { EnglishGreeter() } }
    var counter: Dependency<Counter> { Dependency(self) { Counter() }.singleton }
    var freshCounter: Dependency<Counter> { Dependency(self) { Counter() } }
}

struct ContainerTests {
    @Test func resolvesDefault() {
        #expect(Container().greeter().greet() == "Hello")
    }

    @Test func overrideAndReset() {
        let container = Container()
        container.greeter.register { ThaiGreeter() }
        #expect(container.greeter().greet() == "สวัสดี")

        container.reset()
        #expect(container.greeter().greet() == "Hello")
    }

    @Test func singletonScopeReturnsSameInstance() {
        let container = Container()
        #expect(container.counter() === container.counter())
        #expect(container.freshCounter() !== container.freshCounter())
    }
}
