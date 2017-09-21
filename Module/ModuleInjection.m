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
-(NSDictionary*) dictionaryByAddObjects:(NSArray*)objects forKeys:(NSArray*)keys;
@end
@interface NSArray<ObjectType> (map)
-(NSArray*) map:(id(^)(ObjectType)) func;
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
        NSArray * keys = [interfaces map:^id(Protocol * p) { return NSStringFromProtocol(p);}];
        NSArray * vals = [keys map:^id(id _) { return name;}];
        self.interfaces = [self.interfaces dictionaryByAddObjects:vals forKeys:keys];
        NSLog(@"module[%@] registed for interfaces [%@]",name,[keys componentsJoinedByString:@","]);
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
    NSLog(@"module [%@] loaded",name);
}
@end


@implementation NSDictionary (addObject)
-(NSDictionary*) dictionaryByAddObject:(id)object forKey:(id)key{
    return [self dictionaryByAddObjects:@[object] forKeys:@[key]];
}
-(NSDictionary*) dictionaryByAddObjects:(NSArray*)objects forKeys:(NSArray*)keys{
    NSMutableDictionary * clone = [self mutableCopy];
    [clone addEntriesFromDictionary:[NSDictionary dictionaryWithObjects:objects forKeys:keys]];
    return [clone copy];
}
@end
@implementation NSArray (map)
-(NSArray*) map:(id(^)(id)) func{
    NSMutableArray * rets = [self mutableCopy];
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL * stop) {
        [rets replaceObjectAtIndex:idx withObject:func(obj)];
    }];
    return [rets copy];
}
@end
