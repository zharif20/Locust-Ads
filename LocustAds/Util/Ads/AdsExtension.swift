//
//  Banner.swift
//  LocustAds
//
//  Created by M. Zharif Hadi M. Khairuddin on 30/03/2018.
//  Copyright © 2018 M. Zharif Hadi M. Khairuddin. All rights reserved.
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//    SOFTWARE.


import Foundation
import UIKit
import Firebase
import GoogleMobileAds

/// AdsExtensionDelegate
protocol AdsExtensionDelegate: class {
    /// AdsExtension did open
    func adsExtensionDidOpen(_ adsExtension: AdsExtension)
    /// AdsExtension did close
    func adsExtensionDidClose(_ adsExtension: AdsExtension)
    /// AdsExtension did reward user
    func adsExtension(_ adsExtension: AdsExtension, didRewardUserWithAmount rewardAmount: Int)
}

/**
 AdMob
 A singleton class to manage adverts from Google AdMob.
 */
class AdsExtension: NSObject
{
    /// Banner position
    enum BannerPosition {
        case bottom
        case top
    }
    // MARK: - Static Properties
    /// Shared instance
    static let sharedInstance = AdsExtension()
    
    // MARK: - Properties
    
    var delegate: AdsExtensionDelegate?

    /// Ads
    private var bannerViewConstraint: NSLayoutConstraint?
    private var bannerView: GADBannerView?
    private var interstitialAd: GADInterstitial?
    private var rewardedVideoAd: GADRewardBasedVideoAd?

    /// Banner position
    private var bannerPosition: BannerPosition = .bottom
    /// Banner size
    private var bannerSize: GADAdSize {
        return UIDevice.current.orientation.isLandscape ? kGADAdSizeSmartBannerLandscape : kGADAdSizeSmartBannerPortrait
    }
    
    /// Banner animation duration
    var bannerAnimationDuration = 1.8
    
    /// Interval counter
    private var intervalCounter = 0
    
    /// Check if interstitial video is ready (e.g to show alternative ad)
    /// Will try to reload an ad if it returns false.
    var isInterstitialAds: Bool {
        guard let ad = interstitialAd, ad.isReady else {
            print("Interstitial Ads not ready, Reloading...")
            loadInterstitialAds()
            return false
        }
        return true
    }
    
    /// Check if reward video is ready (e.g to hide a reward video button)
    /// Will try to reload an ad if it returns false.
    var isRewardAds: Bool {
        guard let ad = rewardedVideoAd, ad.isReady else {
            print("Reward Ads not ready, Reloading...")
            loadRewardAds()
            return false
        }
        return true
    }
    
    /// Remove ads e.g for in app purchases
    var removeAds = false {
        didSet {
            guard removeAds else {return}
            interstitialAd?.delegate = nil
            interstitialAd = nil
        }
    }
    
    // MARK: - Init
    
    private override init() {
        super.init()
        print("AdMob SDK version \(GADRequest.sdkVersion())")
        NotificationCenter.default.addObserver(self, selector: #selector(didRotateDevice), name: .UIDeviceOrientationDidChange, object: nil)
    }
    
    // Initialize mobile ads - AppDelegate
    func initializeGoogleMobileAds()
    {
        GADMobileAds.configure(withApplicationID: Constants.ApplicationID)
    }
    
    // MARK: - Setup
    
    /// Set up Ads Extension
    ///
    /// - parameter bannerID: The banner adUnitID for this app.
    /// - parameter interstitialID: The interstitial adUnitID for this app.
    /// - parameter rewardedVideoID: The rewarded video adUnitID for this app.
    func setup(withBannerID bannerID: String?, interstitialID: String?, rewardedVideoID: String?) {
        #if !DEBUG
            bannerViewAdUnitID = bannerID ?? ""
            interstitialAdUnitID = interstitialID ?? ""
            rewardedVideoAdUnitID = rewardedVideoID ?? ""
        #endif
        
        loadInterstitialAds()
        loadRewardAds()
    }
    
    // MARK: - Show Banner
    
    /// Show banner ad
    ///
    /// - parameter viewController: The view controller that will present the ad.
    /// - parameter position: The position of the banner. Defaults to bottom.
    func showBanner(from viewController: UIViewController, at position: BannerPosition = .bottom) {
        guard !removeAds else { return }
        bannerPosition = position
        loadBannerAd(from: viewController)
    }
    
    // MARK: - Show Interstitial
    
    /// Show interstitial ad randomly
    ///
    /// - parameter viewController: The view controller that will present the ad.
    /// - parameter interval: The interval of when to show the ad, e.g every 4th time the method is called. Defaults to nil.
    func showInterstitial(from viewController: UIViewController, withInterval interval: Int? = nil) {
        guard !removeAds, isInterstitialAds else { return }
        
        if let interval = interval {
            intervalCounter += 1
            guard intervalCounter >= interval else { return }
            intervalCounter = 0
        }
        
        interstitialAd?.present(fromRootViewController: viewController)
    }
    
    // MARK: - Show Reward Video
    
    /// Show rewarded video ad
    ///
    /// - parameter viewController: The view controller that will present the ad.
    func showRewardAds(from viewController: UIViewController) {
        guard isRewardAds else {
            let alertController = UIAlertController(title: Constants.Sorry, message: Constants.NoVideo, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: Constants.Ok, style: .cancel, handler: nil))
            viewController.present(alertController, animated: true, completion: nil)
            return
        }
        rewardedVideoAd?.present(fromRootViewController: viewController)
    }
    
    // MARK: - Remove Banner
    
    /// Remove banner ads
    func removeBanner() {
        bannerView?.delegate = nil;
        bannerView?.removeFromSuperview()
        bannerView = nil
        bannerViewConstraint = nil
    }
}


private extension AdsExtension
{
    func loadBannerAd(from viewController: UIViewController)
    {
//        removeBanner()
        bannerView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
        guard let bannerAdView = bannerView else { return }
        viewController.view.addSubview(bannerAdView)
        // Create ad
        bannerAdView.adUnitID = Constants.AdMobAdUnitID
        bannerAdView.delegate = self
        bannerAdView.rootViewController = viewController
//        bannerAdView.isHidden = true
        bannerAdView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add constraints
        let layoutGuide: UILayoutGuide
        if #available(iOS 11, *) {
            layoutGuide = viewController.view.safeAreaLayoutGuide
        } else {
            layoutGuide = viewController.view.layoutMarginsGuide
        }
        
        bannerAdView.leftAnchor.constraint(equalTo: layoutGuide.leftAnchor).isActive = true
        bannerAdView.rightAnchor.constraint(equalTo: layoutGuide.rightAnchor).isActive = true
        
//        switch bannerPosition {
//        case .bottom:
        bannerViewConstraint = bannerAdView.bottomAnchor.constraint(equalTo: layoutGuide.bottomAnchor)
//        case .top:
//            bannerViewConstraint = bannerAdView.topAnchor.constraint(equalTo: layoutGuide.topAnchor)
//        }

//        animateBannerToOffScreenPosition(bannerAdView, from: viewController, withAnimation: false)
        bannerViewConstraint?.isActive = true
        
        // Request ad
        let request = GADRequest()
        #if DEBUG
            request.testDevices = [kGADSimulatorID]
        #endif
        bannerAdView.load(request)
    }
    
    func loadInterstitialAds() {
        interstitialAd = GADInterstitial(adUnitID: Constants.interstitialAdUnitID)
        interstitialAd?.delegate = self
        
        // Request ad
        let request = GADRequest()
        #if DEBUG
                request.testDevices = [kGADSimulatorID, "85130baf6cc789cb4331296dfaa7936f"] //85130baf6cc789cb4331296dfaa7936f
        #endif
        interstitialAd?.load(request)
    }
    
    func loadRewardAds() {
        rewardedVideoAd = GADRewardBasedVideoAd.sharedInstance()
        rewardedVideoAd?.delegate = self
        
        // Request ad
        let request = GADRequest()
        #if DEBUG
            request.testDevices = [kGADSimulatorID, "85130baf6cc789cb4331296dfaa7936f"]
        #endif
        rewardedVideoAd?.load(request, withAdUnitID: Constants.rewardedVideoAdUnitID)
    }
    
}

// MARK: - GAD Banner View Delegate

extension AdsExtension: GADBannerViewDelegate
{
    /// Tells the delegate an ad request loaded an ad.
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        print("adViewDidReceiveAd")
    }
    
    /// Tells the delegate an ad request failed.
    func adView(_ bannerView: GADBannerView,
                didFailToReceiveAdWithError error: GADRequestError) {
        print("adView:didFailToReceiveAdWithError: \(error.localizedDescription)")
    }
    
    /// Tells the delegate that a full-screen view will be presented in response
    /// to the user clicking on an ad.
    func adViewWillPresentScreen(_ bannerView: GADBannerView) {
        print("adViewWillPresentScreen")
    }
    
    /// Tells the delegate that the full-screen view will be dismissed.
    func adViewWillDismissScreen(_ bannerView: GADBannerView) {
        print("adViewWillDismissScreen")
    }
    
    /// Tells the delegate that the full-screen view has been dismissed.
    func adViewDidDismissScreen(_ bannerView: GADBannerView) {
        print("adViewDidDismissScreen")
    }
    
    /// Tells the delegate that a user click will open another app (such as
    /// the App Store), backgrounding the current app.
    func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
        print("adViewWillLeaveApplication")
    }
}

// MARK: - GAD Interstitial Delegate
extension AdsExtension: GADInterstitialDelegate {
    
    func interstitialDidReceiveAd(_ ad: GADInterstitial) {
        print("AdMob interstitial did receive ad from: \(ad.adNetworkClassName ?? "")")
    }
    
    func interstitialWillPresentScreen(_ ad: GADInterstitial) {
//        delegate?.adsExtensionDidOpen(self)
    }
    
    func interstitialWillLeaveApplication(_ ad: GADInterstitial) {
//        delegate?.adsExtensionDidOpen(self)
    }
    
    func interstitialWillDismissScreen(_ ad: GADInterstitial) {
    }
    
    func interstitialDidDismissScreen(_ ad: GADInterstitial) {
//        delegate?.adsExtensionDidClose(self)
        loadInterstitialAds()
    }
    
    func interstitialDidFail(toPresentScreen ad: GADInterstitial) {
    }
    
    func interstitial(_ ad: GADInterstitial, didFailToReceiveAdWithError error: GADRequestError) {
        print(error.localizedDescription)
        // Do not reload here as it might cause endless loading loops if no/slow internet
    }
}

// MARK: - GAD Reward Based Video Ad Delegate
extension AdsExtension: GADRewardBasedVideoAdDelegate {
    
    func rewardBasedVideoAdDidReceive(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        print("AdMob reward based video did receive ad from: \(rewardBasedVideoAd.adNetworkClassName ?? "")")
    }
    
    func rewardBasedVideoAdDidStartPlaying(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
//        delegate?.adsExtensionDidOpen(self)
    }
    
    func rewardBasedVideoAdDidOpen(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
    }
    
    func rewardBasedVideoAdWillLeaveApplication(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
//        delegate?.adsExtensionDidOpen(self)
    }
    
    func rewardBasedVideoAdDidClose(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
//        delegate?.adsExtensionDidClose(self)
        loadRewardAds()
    }
    
    func rewardBasedVideoAdDidCompletePlaying(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        
    }
    
    func rewardBasedVideoAd(_ rewardBasedVideoAd: GADRewardBasedVideoAd, didFailToLoadWithError error: Error) {
        print(error.localizedDescription)
        // Do not reload here as it might cause endless loading loops if no/slow internet
    }
    
    func rewardBasedVideoAd(_ rewardBasedVideoAd: GADRewardBasedVideoAd, didRewardUserWith reward: GADAdReward) {
        print("AdMob reward based video ad did reward user with \(reward)")
//        let rewardAmount = Int(truncating: reward.amount)
//        delegate?.swiftyAd(self, didRewardUserWithAmount: rewardAmount)
    }
}

// MARK: - Callbacks
private extension AdsExtension {
    
    @objc func didRotateDevice() {
        print("SwiftyAd did rotate device")
        bannerView?.adSize = bannerSize
    }
}

// MARK: - Banner Position
private extension AdsExtension {
    
    func animateBannerToOnScreenPosition(_ bannerAd: GADBannerView, from viewController: UIViewController?) {
        bannerAd.isHidden = false
        bannerViewConstraint?.constant = 0
        
        UIView.animate(withDuration: bannerAnimationDuration) {
            viewController?.view.layoutIfNeeded()
        }
    }
    
    func animateBannerToOffScreenPosition(_ bannerAd: GADBannerView, from viewController: UIViewController?, withAnimation: Bool = true) {
        switch bannerPosition {
        case .bottom:
            bannerViewConstraint?.constant = 0 + (bannerAd.frame.height * 3) // *3 due to iPhoneX safe area
        case .top:
            bannerViewConstraint?.constant = 0 - (bannerAd.frame.height * 3) // *3 due to iPhoneX safe area
        }
        
        guard withAnimation else {
            bannerAd.isHidden = true
            return
        }
        
        UIView.animate(withDuration: bannerAnimationDuration, animations: {
            viewController?.view.layoutIfNeeded()
        }, completion: { isSuccess in
            bannerAd.isHidden = true
        })
    }
}

// MARK: - Print
private extension AdsExtension {
    
    /// Overrides the default print method so it print statements only show when in DEBUG mode
    func print(_ items: Any...) {
        #if DEBUG
            Swift.print(items)
        #endif
    }
}
