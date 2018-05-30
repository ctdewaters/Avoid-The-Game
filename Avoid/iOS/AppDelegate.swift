import UIKit
import CoreData
import GameKit
import GoogleMobileAds

public var dataManager = DataManager()

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GADInterstitialDelegate {
    
    var window: UIWindow?
    
    static var interstitial: GADInterstitial!
    
    static var shared: AppDelegate!
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        AppDelegate.shared = self
        
        //Register ads.
        GADMobileAds.configure(withApplicationID: "ca-app-pub-9038325252100119~8660066410")
        
        //Load first.
        AppDelegate.reloadAd()
        
        return true
        
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        if GameScene().gameOn == true{
            GameScene().pauseGame()
        }
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }
        
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        
        
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        UIApplication.shared.isIdleTimerDisabled = false
        dataManager.saveContext()
    }

    class func reloadAd() {
        interstitial = GADInterstitial(adUnitID: "ca-app-pub-9038325252100119/5718493716")
        interstitial.delegate = AppDelegate.shared
        interstitial.load(GADRequest())
    }
    
    class func presentAd(toViewController viewController: UIViewController) {
        if interstitial.isReady {
            interstitial.present(fromRootViewController: viewController)
        }
    }
    
    func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        //Load new ad.
        AppDelegate.reloadAd()
    }
    
    func interstitialDidReceiveAd(_ ad: GADInterstitial) {
    }
    
    func interstitial(_ ad: GADInterstitial, didFailToReceiveAdWithError error: GADRequestError) {
        print(error.localizedDescription)
    }
}

extension UIButton {
    open override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        self.addTarget(self, action: #selector(self.highlight), for: .touchDragEnter)
        self.addTarget(self, action: #selector(self.highlight), for: .touchDown)
        self.addTarget(self, action: #selector(self.unhighlight), for: .touchDragOutside)
    }
    
    @objc func highlight() {
        animator.simpleAnimationForDuration(0.2) {
            self.alpha = 0.7
        }
    }
    
    @objc func unhighlight() {
        animator.simpleAnimationForDuration(0.2) {
            self.alpha = 1
        }
    }
}

