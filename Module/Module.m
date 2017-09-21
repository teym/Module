//
//  Module.m
//  Module
//
//  Created by mike on 2017/9/21.
//  Copyright © 2017年 mike. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ModuleInjection.h"

@interface Module:NSObject
@property (nonatomic,strong) ModuleInjection * injection;
@end

@implementation Module

-(id) init{
    self = [super init];
    
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = self;
        self.injection = [ModuleInjection new];
        NSArray* modules = [[[NSThread mainThread] threadDictionary] objectForKey:@"_module_registes"];
        for (Class cls in modules) {
            NSArray * interfaces = [cls Interfaces];
            interfaces = interfaces ? interfaces : @[];
            [self.injection registModule:NSStringFromClass(cls) class:cls interfaces:interfaces];
        }
    });
    if (self != instance) {
        self = instance;
    }
    return self;
}
@end

ModuleLoader(Module)
