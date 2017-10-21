//
//  Network.swift
//  Interfaces
//
//  Created by 王航 on 2017/10/21.
//  Copyright © 2017年 mike. All rights reserved.
//

import Foundation

@objc public protocol Task:AnyObject {
    @discardableResult
    func response(success:@escaping (Data)->Void, failure:@escaping (Error?)->Void) -> Task
    @discardableResult
    func responseJSON(success:@escaping (Any)->Void, failure:@escaping (Error?)->Void) -> Task
    @discardableResult
    func progress(block:@escaping (Int64,Int64)->Void) -> Task
}

@objc public protocol Network:AnyObject {
    typealias URLMap = (String,String)->String
    @objc var requestMap:URLMap?{get set}
    @objc var reachable:Bool {get}
    func request(url:String, method:String, parameters:[String:Any], headers:[String:String]) -> Task
    func upload(url:String,files:[String:AnyObject], headers:[String:String], handle:@escaping (Task?, Error?)->Void)
}
