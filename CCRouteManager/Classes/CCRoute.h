//
//  CCRoute.h
//  CCRouteManager
//
//  Created by mac on 2023/1/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CCRoute : NSObject
// scheme
@property (nonatomic,copy) NSString *scheme;
/// 路径
@property (nonatomic,copy) NSString *path;
/// viewController 对应的类名
@property (nonatomic,copy) NSString *className;
/// modal模式 默认 NO
@property (nonatomic, assign) BOOL present;
/// 模态动画样式 默认0
@property (nonatomic, assign) UIModalPresentationStyle presentStyle;
/// 是否动画 默认YES
@property (nonatomic, assign) BOOL animate;
/// 是否是根视图
@property (nonatomic, assign) BOOL root;
/// 是否需要登录 默认NO
@property (nonatomic, assign) BOOL needLogin;
/// 必填参数
@property (nonatomic,strong) NSArray *requiredParams;
/// 默认参数
@property (nonatomic,strong) NSMutableDictionary *defaultParams;

-(NSDictionary *)keyValues;

+(NSDictionary *)defaultParams;
@end

NS_ASSUME_NONNULL_END
