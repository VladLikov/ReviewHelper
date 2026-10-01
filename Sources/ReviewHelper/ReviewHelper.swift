// The Swift Programming Language
// https://docs.swift.org/swift-book

import UIKit
import StoreKit
import MessageUI

public final class ReviewHelper: NSObject {
        
    private var minLaunches: Int = 0
    private var minDays: Int = 0

    public init(email: String? = nil, appID: String? = nil) {
        self.email = email
        self.appID = appID
    }
    
    /// Requests an App Store review without first asking whether the user likes the app.
    /// `presentingVC` is retained for source compatibility; no custom alert is presented.
    public func requestImmediately(presentingVC: UIViewController? = nil) {
        requestSystemReviewOrFallback()
    }
    
    private let ud = UserDefaults.standard
    
    public var launches: Int {
        get { ud.integer(forKey: #function) }
        set { ud.set(newValue, forKey: #function) }
    }
    
    public var firstLaunchDate: Date? {
        get { ud.object(forKey: #function) as? Date }
        set { ud.set(newValue, forKey: #function) }
    }
    
    public var lastReviewDate: Date? {
        get { ud.object(forKey: #function) as? Date }
        set { ud.set(newValue, forKey: #function) }
    }
     
    public var lastReviewVersion: String? {
        get { ud.string(forKey: #function) }
        set { ud.set(newValue, forKey: #function) }
    }
    
    public var daysAfterFirstLaunch: Int {
        if let date = firstLaunchDate {
            return daysBetween(date, Date())
        }
        return 0
    }
    
    public var daysAfterLastReview: Int {
        if let date = lastReviewDate {
            return daysBetween(date, Date())
        }
        return 0
    }
    
    public var isNeeded: Bool {
        launches >= minLaunches &&
        daysAfterFirstLaunch >= minDays &&
        (lastReviewDate == nil || daysAfterLastReview >= 125) &&
        lastReviewVersion != version
    }

    /// Requests an App Store review when the launch, day, and version conditions are met.
    /// `presentingVC` is retained for source compatibility; no sentiment survey is presented.
    /// Returns whether a request was attempted, not whether StoreKit displayed a prompt.
    @discardableResult
    public func requestIfNeeded(minLaunches: Int = 0, minDays: Int = 0, presentingVC: UIViewController? = nil) -> Bool {
        self.minLaunches = minLaunches
        self.minDays = minDays
        if firstLaunchDate == nil { firstLaunchDate = Date() }
        launches += 1
        guard isNeeded else { return false }
        lastReviewDate = Date()
        lastReviewVersion = version
        requestSystemReviewOrFallback()
        return true
    }
    
    private func requestSystemReviewOrFallback() {
        DispatchQueue.main.async {
            
            #if os(iOS)
            guard UIApplication.shared.applicationState == .active else {
                self.openWriteReviewPageIfPossible()
                return
            }
            if #available(iOS 14.0, *) {
                let activeScene = UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .first { $0.activationState == .foregroundActive }
                
                if let scene = activeScene {
                    SKStoreReviewController.requestReview(in: scene)
                } else {
                    // нет активной сцены — уходим во fallback
                    self.openWriteReviewPageIfPossible()
                }
            } else {
                SKStoreReviewController.requestReview()
            }
            #else
            SKStoreReviewController.requestReview()
            #endif
        }
    }
    
    private func openWriteReviewPageIfPossible() {
        guard
            let appID,
            let url = URL(string: "itms-apps://itunes.apple.com/app/id\(appID)?action=write-review")
        else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    internal var version: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "0"
    }
    
    internal func daysBetween(_ start: Date, _ end: Date) -> Int {
        let calendar = Calendar.current
        let a = calendar.startOfDay(for: start)
        let b = calendar.startOfDay(for: end)
        return calendar.dateComponents([.day], from: a, to: b).day ?? 0
    }
    
    // 3) email хранится в инстансе
    private let email: String?
    private let appID: String?
}

// MARK: - Mail

extension ReviewHelper: MFMailComposeViewControllerDelegate {
    
    public func mailComposeController(_ controller: MFMailComposeViewController,
                                      didFinishWith result: MFMailComposeResult,
                                      error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    private func sendMail(presentingVC: UIViewController) {
        guard let email else { return }
        
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController.getDefault(for: email)
            presentingVC.present(mail, animated: true)
        } else if let url = URL(string: "mailto:\(email)") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}
