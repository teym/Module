//
//  Module.swift
//  Module
//
//  Created by 王航 on 2017/9/28.
//  Copyright © 2017年 mike. All rights reserved.
//

import Foundation
import Interfaces

protocol ModuleLoader {
    func modules()->[AnyClass]
}

extension Array {
    public func appendBy(_ newElement: Element) -> Array<Element> {
        var ret = self
        ret.append(newElement)
        return ret
    }
}

class RootModule : NSObject, ModuleInject {
    let modules:[String:AnyClass]
    let interfaces:[String:String]
    var instances = [String:AnyObject]()
    private var circle = [String]()
    init(loader:ModuleLoader) {
        self.modules = Dictionary(uniqueKeysWithValues: loader.modules().map({ (m) -> (String,AnyClass) in
            return (String(describing:m),m)
        }))
        print("[module] modules:",self.modules)
        self.interfaces = self.modules.reduce([:], { (result, kv) -> [String:String] in
            let ins = (kv.value as? Module.Type)?.interfaces() ?? []
            let maps = ins.map({(p) -> (String,String) in
                return (String(describing: p),kv.key)
            })
            let dict = Dictionary(uniqueKeysWithValues: maps)
            return result.merging(dict, uniquingKeysWith: { (a, b) -> String in
                return a
            })
        })
        super.init()
        
        let ms = self.modules
        let loadOnStartModules = self.modules.keys.filter { (name) -> Bool in
            return (ms[name] as? Module.Type)?.loadOnStart() ?? false
        }
        loadOnStartModules.forEach {try? self.loadModule(name: $0)}
    }
    func instance(interface: AnyObject) throws -> AnyObject {
        let ints = self.interfaces
        let key = String(describing: interface)
        print("[module] instance:",key)
        guard let objKey = ints[key] else {
            throw ModuleInjectError.ModuleNotFound(msg: key)
        }
        let vals = self.instances
        if let val = vals[objKey]{
            return val
        }
        try self.loadModule(name:objKey)
        let vals2 = self.instances
        if let val = vals2[objKey]{
            return val
        }
        throw ModuleInjectError.ModuleNotFound(msg: key)
    }
    func loadModule(name:String) throws{
        try syncRunOnMain {
            guard self.instances[name] == nil else {
                return
            }
            if let module = self.modules[name] as? Module.Type {
                let msg = self.circle.appendBy(name).joined(separator: " -> ")
                if self.circle.contains(name) {
                    throw ModuleInjectError.CircleDependency(msg: msg)
                }
                self.circle.append(name)
                let m = module.init(inject: self)
                self.instances[name] = m as AnyObject
                _ = self.circle.popLast()
                print("[module] module loaded:",name)
            }
        }
    }
    func syncRunOnMain(block:()throws ->Void) rethrows{
        if Thread.isMainThread {
            try block()
        }else{
            try DispatchQueue.main.sync(execute: block)
        }
    }
}

class Loader:NSObject,ModuleLoader {
    private var cache:[String:Bool] = [:]
    
    func modules() -> [AnyClass] {
        var classes = [AnyClass]()
        let prefix = self.imagePrefix()
        var imageCount:UInt32 = 0
        let images = objc_copyImageNames(&imageCount)
        for i in 0 ..< imageCount {
            let imagePath = String(cString: images[Int(i)])
            if imagePath.hasPrefix(prefix)
                && !(imagePath.split(separator: "/").last ?? "").hasPrefix("libswift") {
                let list = self.checkImage(image: images[Int(i)])
                for cls in list{
                    classes = self.addIfIsFinalClass(classes: classes, cls: cls)
                }
            }
        }
        free(images)
        return classes
    }
    func checkImage(image:UnsafePointer<Int8>) -> [AnyClass] {
        var rets = [AnyClass]()
        var count:UInt32 = 0
        if let classes = objc_copyClassNamesForImage(image, &count){
            for i in 0 ..< count {
                if let cls = objc_lookUpClass(classes[Int(i)]) {
                    if checkProtocol(cls: cls){
                        rets.append(cls)
                    }
                }
            }
            free(classes)
        }
        return rets
    }
    func imagePrefix()->String{
        if let thisImg = class_getImageName(Loader.self).map({String(cString: $0)}) {
            var paths = thisImg.split(separator: "/")
            paths.removeLast(2)
            return "/" + paths.joined(separator: "/")
        }
        return "/"
    }
    func checkProtocol(cls:AnyClass) -> Bool{
        let name = String(describing: cls)
        if let ret = cache[name] {
            return ret
        }
        let key = NSStringFromProtocol(Module.self as Protocol) //"Interfaces.Module"
        var protocolCount:UInt32 = 0
        if let protocols = class_copyProtocolList(cls, &protocolCount){
            for j in 0 ..< protocolCount {
                let protocolName = NSStringFromProtocol(protocols[Int(j)])
                if key == protocolName {
                    cache[String(describing: cls)] = true
                    return true
                }
            }
        }
        if let sup = class_getSuperclass(cls) {
            return checkProtocol(cls: sup)
        }
        cache[String(describing: cls)] = false
        return false
    }
    func addIfIsFinalClass(classes:[AnyClass],cls:AnyClass) -> [AnyClass] {
        var list = classes
        for i in (0 ..< list.count).reversed() {
            if list[i].isSubclass(of: cls) {
                return list
            }
            if cls.isSubclass(of: list[i]) {
                list.remove(at: i)
            }
        }
        list.append(cls)
        return list
    }
}
public let root:ModuleInject = RootModule(loader: Loader())
