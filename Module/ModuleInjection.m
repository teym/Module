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
@property (copy) NSDictionary * instances;
@property (copy) NSDictionary * interfaces;
@end

@implementation ModuleInjection
-(id) init{
    self = [super init];
    if (self) {
        self.modules = @{};
        self.instances = @{};
        self.interfaces = @{};
    }
    return self;
}
-(void) registModule:(Class) cls interfaces:(NSArray<Protocol*>*) interfaces loadOnStart:(BOOL)load{
    void(^regist)(void) = ^{
        NSString * name = NSStringFromClass(cls);
        NSAssert(![self.modules objectForKey:name], @"module [%@] exist", name);
        self.modules = [self.modules dictionaryByAddObject:@{@"class":cls,
                                                             @"load":@(load),
                                                             @"interfaces":interfaces}
                                                    forKey:name];
        for (Protocol* p in interfaces) {
            self.interfaces = [self.interfaces dictionaryByAddObject:name forKey:NSStringFromProtocol(p)];
        }
    };
    if ([NSThread isMainThread]) {
        regist();
    }else{
        dispatch_sync(dispatch_get_main_queue(), regist);
    }
}
-(id) instanceForInterface:(Protocol *)interface{
    NSString * inf = NSStringFromProtocol(interface);
    NSString * name = [self.interfaces objectForKey:inf];
    NSAssert(name, @"interface[%@] not found",inf);
    id instance = [self.instances objectForKey:name];
    if (instance) {
        return instance;
    }
    if (![NSThread isMainThread]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self loadModuleFor:name];
        });
    }else{
        [self loadModuleFor:name];
    }
    instance = [self.instances objectForKey:name];
    NSAssert(instance, @"cant find module for interface [%@]",inf);
    return instance;
}
-(void) boot{
    NSArray * names = [self.modules allKeys];
    for (NSString* name in names) {
        if ([[[self.modules objectForKey:name] objectForKey:@"load"] boolValue]) {
            [self loadModuleFor:name];
        }
    }
}
-(void) loadModuleFor:(NSString*) name{
    NSAssert([NSThread isMainThread], @"mast run in main thread");
    if ([self.instances objectForKey:name]) {
        return;
    }
    NSDictionary * module = [self.modules objectForKey:name];
    Class cls = [module objectForKey:@"class"];
    id theModule = [[cls alloc] initWithInjection:self];
    NSAssert(![self.modules objectForKey:name], @"module exist??");
    self.instances = [self.instances dictionaryByAddObject:theModule forKey:name];
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
