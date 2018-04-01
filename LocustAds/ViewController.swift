//
//  ViewController.swift
//  LocustAds
//
//  Created by M. Zharif Hadi M. Khairuddin on 30/03/2018.
//  Copyright © 2018 M. Zharif Hadi M. Khairuddin. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var testButton = UIButton()
    var rewardVideoAds = UIButton()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        // Calling Ads Banner
        AdsExtension.sharedInstance.showBanner(from: self)
        
        self.testButton.backgroundColor = .gray
        self.testButton.translatesAutoresizingMaskIntoConstraints = false
        self.testButton.layer.cornerRadius = 5
        self.testButton.clipsToBounds = true
        self.view.addSubview(self.testButton)
        self.testButton.addTarget(self, action: #selector(showInterstitial), for: .touchUpInside)
        
        self.rewardVideoAds.backgroundColor = .red
        self.rewardVideoAds.translatesAutoresizingMaskIntoConstraints = false
        self.rewardVideoAds.layer.cornerRadius = 5
        self.rewardVideoAds.clipsToBounds = true
        self.view.addSubview(self.rewardVideoAds)
        self.rewardVideoAds.addTarget(self, action: #selector(showRewards), for: .touchUpInside)
        
        self.testButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        self.testButton.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        self.testButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        self.testButton.widthAnchor.constraint(equalToConstant: 100).isActive = true
        
        self.rewardVideoAds.topAnchor.constraint(equalTo: self.testButton.bottomAnchor, constant: 10).isActive = true
        self.rewardVideoAds.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        self.rewardVideoAds.heightAnchor.constraint(equalToConstant: 50).isActive = true
        self.rewardVideoAds.widthAnchor.constraint(equalToConstant: 100).isActive = true
    }
    
    // Interstitial Ads
    @objc func showInterstitial() {
        AdsExtension.sharedInstance.showInterstitial(from: self)
    }
    
    // Video Reward Ads
    @objc func showRewards() {
        AdsExtension.sharedInstance.showRewardAds(from: self)
    }

}


