    //
    //  ModuleInjection.m
    //  Module
    //
    //  Created by mike on 2017/9/21.
    //  Copyright © 2017年 mike. All rights reserved.
    //

#import "ModuleInjection.h"

@interface NSDictionary (addObject)
-(NSDictionary*) dictionaryByAddObject:(id) object forKey:(id) key;
@end

@interface ModuleInjection ()
@property (copy) NSDictionary * modules;
@property (copy) NSDictionary * moduleImps;
@end

@implementation ModuleInjection
-(id) init{
    self = [super init];
    if (self) {
        self.modules = @{};
        self.moduleImps = @{};
    }
    return self;
}
-(void) registModule:(NSString *)name class:(Class)cls interfaces:(NSArray<Protocol *> *)interfaces{
    void(^regist)(void) = ^{
        NSAssert(![self.modules objectForKey:name], @"module [%@] exist", name);
        
        self.modules = [self.modules dictionaryByAddObject:@{@"class":cls,
                                                             @"interfaces":interfaces}
                                                    forKey:name];
    };
    if ([NSThread isMainThread]) {
        regist();
    }else{
        dispatch_sync(dispatch_get_main_queue(), regist);
    }
}
-(id) instanceForInterface:(Protocol *)interface{
    NSAssert(interface, @"interface cant be nil");
    NSDictionary * imps = self.moduleImps;
    if ([imps objectForKey:interface]) {
        return [imps objectForKey:interface];
    }
    if (![NSThread isMainThread]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self loadModuleFor:interface];
        });
    }else{
        [self loadModuleFor:interface];
    }
    id imp = [self.moduleImps objectForKey:interface];
    NSAssert(imp, @"cant find module for interface [%@]",NSStringFromProtocol(interface));
    return imp;
}
-(void) loadModuleFor:(Protocol*) interface{
    NSAssert([NSThread isMainThread], @"mast run in main thread");
    if ([self.moduleImps objectForKey:interface]) {
        return;
    }
    for (NSString * name in [self.modules allKeys]) {
        NSDictionary * module = [self.modules objectForKey:name];
        NSArray<Protocol*>* protocols = [module objectForKey:@"interfaces"];
        if ([protocols indexOfObject:interface] != NSNotFound){
            Class cls = [module objectForKey:@"class"];
            id theModule = [[cls alloc] initWithInjection:self];
            NSAssert(![self.moduleImps objectForKey:interface], @"module exist??");
            self.moduleImps  = [self.moduleImps dictionaryByAddObject:theModule forKey:interface];
            return;
        }
    }
}
@end


@implementation NSDictionary (addObject)
-(NSDictionary*) dictionaryByAddObject:(id)object forKey:(id)key{
    NSAssert(![self objectForKey:key], @"key exist");
    NSMutableDictionary * dict = [self mutableCopy];
    [dict setObject:object forKey:key];
    return [dict copy];
}
@end
