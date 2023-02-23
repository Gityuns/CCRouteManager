//
//  CCRouteManager.h
//  CCRouteManager
//
//  Created by mac on 2023/1/3.
//

#import <Foundation/Foundation.h>
#import "CCRoute.h"

NS_ASSUME_NONNULL_BEGIN

@interface CCRouteManager : NSObject

+(instancetype)shared;

// 是否登录
@property (nonatomic, assign) BOOL isLogin;
// 当跳转需要登录的页面，而用户没用登录时
@property (nonatomic, copy) NSString *loginURL;
// 白名单
@property (nonatomic, strong) NSArray *whiteHosts;
// 黑名单
@property (nonatomic, strong) NSArray *blackHosts;
// 重定向
@property (nonatomic, strong) NSDictionary *redirects;
// 使用json文件的方式初始化路由
-(void)initRouteFromFile:(NSString *)filePath;
// 注册路由
-(void)registerPage:(CCRoute *)page;
// 获取当前控制器
+ (UIViewController *)currentViewController;
// 通过scheme 创建vc
+(UIViewController *)pageFromURL:(NSString *)urlString params:(NSDictionary *_Nullable)params;

+(BOOL)openURL:(NSString *)urlString;
+(BOOL)openURL:(NSString *)urlString params:(NSDictionary *_Nullable)params;
+(BOOL)openURL:(NSString *)urlString params:(NSDictionary *_Nullable)params completionHandle:(void(^_Nullable)(NSDictionary *_Nullable info,NSError *_Nullable error))completion;
@end

NS_ASSUME_NONNULL_END
