//
//  CCRouteManager.m
//  CCRouteManager
//
//  Created by mac on 2023/1/3.
//

#import "CCRouteManager.h"

@interface CCRouteManager ()

@property (nonatomic, strong) NSMutableDictionary *route;
@end

@implementation CCRouteManager

-(NSMutableDictionary *)route{
    if (_route == nil) {
        _route = [[NSMutableDictionary alloc]init];
    }
    return _route;
}

+(instancetype)shared{
    static CCRouteManager *shard = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shard = [[CCRouteManager alloc]init];
    });
    return shard;
}

-(void)initRouteFromFile:(NSString *)filePath{
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    NSError *err;
    NSDictionary *map = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&err];
    if (err) {
        NSLog(@"注册路由失败：文件不合法");
    }
    [self.route addEntriesFromDictionary:map];
}

-(void)registerPage:(CCRoute *)page{
    NSDictionary *route = [self.route objectForKey:page.scheme];
    if (route) {
        NSMutableDictionary *map = [[NSMutableDictionary alloc]initWithDictionary:route];
        [map setObject:[page keyValues] forKey:page.path];
        [self.route setObject:map forKey:page.scheme];
    }else{
        [self.route setObject:@{
                    page.path: [page keyValues]
        } forKey:page.scheme];
    }
}

+(BOOL)openURL:(NSString *)urlString{
    return [self openURL:urlString params:nil];
}

+(BOOL)openURL:(NSString *)urlString params:(NSDictionary *)params{
    return [self openURL:urlString params:params completionHandle:nil];
}

+(BOOL)openURL:(NSString *)urlString params:(NSDictionary *)params completionHandle:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completion{
    // 校验url
    NSError *err = [self validateURL:urlString];
    if (err) {
        if (completion) completion(nil,err);
        return NO;
    }
    // 路由重定向
    NSString *urlStr = [self redirectURL:urlString];
    NSURL *url = [NSURL URLWithString:urlStr];
    // 检测路由是否注册
    NSDictionary *route = [self routeForURL:url];
    if (route == nil) {
        err = [self errorWithMsg:@"路由未注册"];
        if (completion) completion(nil,err);
    }
    // 校验必填参数
    NSDictionary *queryParams = [self queryParams:url];
    // 默认参数
    NSDictionary *defaultParams = [route objectForKey:@"defaultParams"];
    // 全部参数
    NSMutableDictionary *fullParams = [[NSMutableDictionary alloc]initWithDictionary:[CCRoute defaultParams]];
    [fullParams addEntriesFromDictionary:defaultParams];
    [fullParams addEntriesFromDictionary:queryParams];
    if (params) {
        [fullParams addEntriesFromDictionary:params];
    }
    err = [self validateRequiredParams:route fullParams:fullParams];
    if (err) {
        if (completion) completion(nil,err);
    }
    if (completion) completion(route,nil);
    // 页面跳转
    BOOL result = [self openPage:url fullParams:fullParams];
    if (result == NO) {
        err = [self errorWithMsg:@"登录页路由未配置"];
        if (completion) completion(nil,err);
    }
    return result;
}

+(BOOL)openPage:(NSURL *)url fullParams:(NSDictionary *)params{
    UIViewController *viewController = [self pageFromURL:url.absoluteString params:params];
    BOOL needLogin = [[params objectForKey:@"needLogin"] boolValue];
    CCRouteManager *shared = [CCRouteManager shared];
    if (needLogin) {
        if (!shared.isLogin && shared.loginURL) {
            [self openURL:shared.loginURL];
        }else{
            return NO;
        }
    }
    NSDictionary *redirect = params[@"redirect"];
    if (redirect) {
        NSString *key = redirect[@"key"];
        NSDictionary *redirectParams = redirect[@"params"];
        NSString *urlString =  redirect[@"url"];
        if (key && urlString) {
            BOOL result = [params[key] boolValue];
            if (result == NO) {
                [CCRouteManager openURL:urlString params:redirectParams];
                return NO;
            }
        }
    }
    UIViewController *currentVC = [self currentViewController];
    BOOL root = [[params objectForKey:@"root"] boolValue];
    if (root && currentVC.tabBarController) {
        NSArray *viewControllers = [currentVC.tabBarController viewControllers];
        for (NSInteger i = 0; i<viewControllers.count; i++) {
            UIViewController *vc = viewControllers[i];
            if ([[vc class] isEqual:[viewController class]]) {
                [currentVC.tabBarController setSelectedIndex:i];
                return YES;
            }
        }
        return NO;
    }
    BOOL present = [[params objectForKey:@"present"] boolValue];
    BOOL animate = [[params objectForKey:@"animate"] boolValue];
    NSInteger style = [[params objectForKey:@"presentStyle"] integerValue];
    if (currentVC.navigationController && present == NO) {
        [currentVC.navigationController pushViewController:viewController animated:animate];
    }else{
        viewController.modalPresentationStyle = style;
        [currentVC presentViewController:viewController animated:animate completion:nil];
    }
    return YES;
}

//获取当前屏幕显示的viewcontroller
+ (UIViewController *)currentViewController{
    UIViewController *rootViewController = [self getViewControllerWindow].rootViewController;
    UIViewController *currentVC = [self getCurrentVCFrom:rootViewController];
    return currentVC;
}

+(UIViewController *)pageFromURL:(NSString *)urlString params:(NSDictionary *_Nullable)params{
    NSURL  *url = [NSURL URLWithString:urlString];
    NSDictionary *route = [self routeForURL:url];
    NSString *className = [route objectForKey:@"className"];
    Class clss = NSClassFromString(className);
    if (clss == nil) {
        clss = [UIViewController class];
    }
    UIViewController *viewController = [[clss alloc]init];
    for (NSString *key in params) {
        [viewController setValue:params[key] forKey:key];
    }
    return viewController;
}

//获取RootViewController所在的window
+ (UIWindow*)getViewControllerWindow{
    UIWindow *window = [self keyWindow];
    if (window.windowLevel != UIWindowLevelNormal) {
        NSArray *windows = [UIApplication sharedApplication].windows;
        for (UIWindow *target in windows) {
            if (target.windowLevel == UIWindowLevelNormal) {
                window = target;
                break;
            }
        }
    }
    return window;
}

+(UIWindow *)keyWindow{
    UIWindow* window = nil;
    if (@available(iOS 13.0, *)){
        for (UIWindowScene* windowScene in [UIApplication sharedApplication].connectedScenes){
            if (windowScene.activationState == UISceneActivationStateForegroundActive){
                  window = windowScene.windows.firstObject;
                break;
            }
        }
    }else{
        window = [UIApplication sharedApplication].delegate.window;
    }
    return window;
}

+ (UIViewController *)getCurrentVCFrom:(UIViewController *)rootVC{
    UIViewController *currentVC;
    if ([rootVC presentedViewController]) {
        // 视图是被presented出来的
        while ([rootVC presentedViewController]) {
            rootVC = [rootVC presentedViewController];
        }
    }
    if ([rootVC isKindOfClass:[UITabBarController class]]) {
        // 根视图为UITabBarController
        currentVC = [self getCurrentVCFrom:[(UITabBarController *)rootVC selectedViewController]];
    } else if ([rootVC isKindOfClass:[UINavigationController class]]){
        // 根视图为UINavigationController
        currentVC = [self getCurrentVCFrom:[(UINavigationController *)rootVC visibleViewController]];
    } else {
        // 根视图为非导航类
        currentVC = rootVC;
    }
    return currentVC;
}


/// 校验url 合法
/// 白名单检测
/// 黑名单过滤
/// @param urlString 地址
+(NSError *_Nullable)validateURL:(NSString *)urlString{
    NSString *errMsg;
    NSString *urlStr = [NSString stringWithFormat:@"%@",urlString];
    NSURL *url = [NSURL URLWithString:urlStr];
    if (url == nil) {
        errMsg = @"url 不合法";
        return [self errorWithMsg:errMsg];
    }
    CCRouteManager *router = [CCRouteManager shared];
    if (router.whiteHosts && router.whiteHosts.count>0) {
        if (![router.whiteHosts containsObject:url.host]) {
            errMsg = @"url 不在白名单类";
            return [self errorWithMsg:errMsg];
        }
    }
    if (router.blackHosts && router.blackHosts.count>0) {
        if ([router.blackHosts containsObject:url.host]) {
            errMsg = @"url 在黑名单中";
            return [self errorWithMsg:errMsg];
        }
    }
    return nil;
}

// 路由重定向
+(NSString *)redirectURL:(NSString *)urlString{
    NSDictionary *redirects = [CCRouteManager shared].redirects;
    if (redirects == nil) {
        return urlString;
    }
    NSURL *url = [NSURL URLWithString:urlString];
    NSString *fullPath = [NSString stringWithFormat:@"%@%@%@",url.scheme, url.host,url.path];
    if ([redirects.allKeys containsObject:fullPath]) {
        urlString = [urlString stringByReplacingOccurrencesOfString:fullPath withString:redirects[fullPath]];
    }
    return urlString;
}

// 校验路由信息是否注册
+(NSDictionary *_Nullable)routeForURL:(NSURL *)url{
    NSDictionary *route = [CCRouteManager shared].route;
    NSDictionary *schemeRoute = [route objectForKey:url.scheme];
    NSString *path = [NSString stringWithFormat:@"%@%@",url.host, url.path];
    NSDictionary *pathRoute = [schemeRoute objectForKey:path];
    return pathRoute;
}

// query参数
+(NSDictionary *)queryParams:(NSURL *)url{
    NSString *queryStr = url.query;
    if (queryStr == nil) {
        return @{};
    }
    NSArray *queryArr = [queryStr componentsSeparatedByString:@"&"];
    NSMutableDictionary *params = [[NSMutableDictionary alloc]init];
    for (NSString *param in queryArr) {
        NSArray *keyValue = [param componentsSeparatedByString:@"="];
        [params setObject:keyValue.lastObject forKey:keyValue.firstObject];
    }
    return params;
}

+(NSError *_Nullable)validateRequiredParams:(NSDictionary *)route fullParams:(NSDictionary *)params{
    NSArray *requiredParams = [route objectForKey:@"requiredParams"];
    for (NSString *key in requiredParams) {
        if (![params.allKeys containsObject:key]) {
            NSString *errMsg = [NSString stringWithFormat:@"缺少必填参数%@",key];
            return [self errorWithMsg:errMsg];
        }
    }
    return nil;
}

+(NSError *)errorWithMsg:(NSString *)errMsg{
    return [NSError errorWithDomain:@"CCRouteManager" code:-1 userInfo:@{
        NSLocalizedDescriptionKey:errMsg,
    }];
}
@end
