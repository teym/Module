//
//  ModuleTests.swift
//  ModuleTests
//
//  Created by 王航 on 2017/9/28.
//  Copyright © 2017年 mike. All rights reserved.
//

import XCTest
@testable import Module

protocol InterfaceA {
}
protocol InterfaceB {
}
protocol InterfaceC {
}

class ModuleA:NSObject, Module, InterfaceA{
    static func interfaces() -> [AnyObject] {
        return [InterfaceA.self as AnyObject]
    }
    static func loadOnStart() -> Bool {
        return true
    }
    required init(inject: ModuleInject) {
        super.init()
    }
}
class ModuleSA: ModuleA {
}

class ModuleB: NSObject, Module, InterfaceB {
    static func interfaces() -> [AnyObject] {
        return [InterfaceB.self as AnyObject]
    }
    static func loadOnStart() -> Bool {
        return true
    }
    required init(inject: ModuleInject) {
        super.init()
    }
}
class ModuleSB: ModuleB {
}

class ModuleCA:NSObject, Module, InterfaceA{
    static func interfaces() -> [AnyObject] {
        return [InterfaceA.self as AnyObject]
    }
    static func loadOnStart() -> Bool {
        return false
    }
    required init(inject: ModuleInject) {
        super.init()
        let _:InterfaceB? = try? inject.instance()
    }
}

class ModuleCB: NSObject, Module, InterfaceB {
    static func interfaces() -> [AnyObject] {
        return [InterfaceB.self as AnyObject]
    }
    static func loadOnStart() -> Bool {
        return false
    }
    required init(inject: ModuleInject) {
        super.init()
        let _:InterfaceA? = try? inject.instance()
    }
}

class Mockloader:Loader {
    let _modules:[AnyClass]
    init(modules:[AnyClass]) {
        self._modules = modules
    }
    override func modules() -> [AnyClass] {
        return self._modules
    }
}

class ModuleTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testLoader(){
        let modules = Loader().modules()
        let modulesStr = modules.map { String(describing: $0) }
        let targets = [ModuleSA.self,ModuleSB.self,ModuleCA.self,ModuleCB.self]
        let targetsStr = targets.map { String(describing: $0) }
        XCTAssertEqual(Set(modulesStr), Set(targetsStr),"loader must be \(targetsStr.joined(separator: ","))")
        
        let root = RootModule(loader: Mockloader(modules: targets))
        let rootModules = root.modules.mapValues({String(describing: $0)})
        let targetModules = Dictionary(uniqueKeysWithValues:targetsStr.map({($0,$0)}))
        XCTAssertEqual(rootModules, targetModules)
    }
    
    func testRoot() {
        //mock load
        let loader = Mockloader(modules: [ModuleA.self,ModuleB.self])
        let root = RootModule(loader: loader)
        
        let insA:InterfaceA? = try? root.instance()
        XCTAssert(insA != nil && insA! is ModuleA, "interfaceA must be ModuleA instance")
        let insB:InterfaceB? = try? root.instance()
        XCTAssert(insB != nil && insB! is ModuleB, "interfaceB must be ModuleB instance")
        var ret:InterfaceC?
        XCTAssertThrowsError(ret=try root.instance())
        XCTAssertNil(ret)
    }
    
    func testCircle() {
        let loader = Mockloader(modules: [ModuleCA.self,ModuleCB.self])
        let root = RootModule(loader: loader)
        var ret:InterfaceA?
        XCTAssertThrowsError(ret=try root.instance())
        XCTAssertNil(ret)
    }
    
    func testLoadOnStart() {
        let loader = Mockloader(modules: [ModuleA.self,ModuleB.self])
        let root = RootModule(loader: loader)
        
        XCTAssertEqual(Set(root.instances.keys), Set(loader._modules.map({String(describing: $0)})))
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
            _ = Loader().modules()
        }
    }
}
