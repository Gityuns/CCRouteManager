//
//  CCRoute.m
//  CCRouteManager
//
//  Created by mac on 2023/1/3.
//

#import "CCRoute.h"

@interface CCRoute ()

@property (nonatomic, assign) BOOL isAnimateSet;
@end
@implementation CCRoute
@synthesize animate = _animate;

-(BOOL)animate{
    if(_isAnimateSet){
        _animate = YES;
    }
    return _animate;
}

-(void)setAnimate:(BOOL)animate{
    _isAnimateSet = YES;
    _animate = animate;
}

-(NSDictionary *)keyValues{
    return @{
        @"scheme": self.scheme,
        @"path": self.path,
        @"className": self.className,
        @"requiredParams": self.requiredParams,
        @"defaultParams": self.defaultParams
    };
}

-(NSMutableDictionary *)defaultParams{
    if (_defaultParams == nil) {
        _defaultParams = [[NSMutableDictionary alloc]initWithDictionary:@{
            @"present": @(self.present),
            @"animate": @(self.animate),
            @"root":  @(self.root),
            @"needLogin": @(self.needLogin),
            @"presentStyle": @(self.presentStyle)
        }];
    }
    return _defaultParams;
}

+(NSDictionary *)defaultParams{
    return @{
        @"present": @(NO),
        @"animate": @(YES),
        @"root":  @(NO),
        @"needLogin": @(NO),
        @"presentStyle": @(0)
    };
}
@end
