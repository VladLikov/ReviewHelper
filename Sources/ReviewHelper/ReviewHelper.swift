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
    
    public func requestImmediately(presentingVC: UIViewController? = nil) {
        if let presentingVC {
            showAlert(presentingVC: presentingVC)
        } else {
            requestSystemReviewOrFallback()
        }
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

    @discardableResult
    public func requestIfNeeded(minLaunches: Int = 0, minDays: Int = 0, presentingVC: UIViewController? = nil) -> Bool {
        self.minLaunches = minLaunches
        self.minDays = minDays
        if firstLaunchDate == nil { firstLaunchDate = Date() }
        launches += 1
        guard isNeeded else { return false }
        lastReviewDate = Date()
        lastReviewVersion = version
        if let presentingVC {
            showAlert(presentingVC: presentingVC)
        } else {
            requestSystemReviewOrFallback()
        }
        return true
    }
    
    private func showAlert(presentingVC: UIViewController) {
        DispatchQueue.main.async {
            let title = NSLocalizedString("Do you like the app?", bundle: .module, comment: "")
            let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
            
            let dislikeAction = UIAlertAction(
                title: NSLocalizedString("No", bundle: .module, comment: ""),
                style: .default
            ) { _ in
                self.showEmailAlert(presentingVC: presentingVC)
            }
            
            let likeAction = UIAlertAction(
                title: NSLocalizedString("Yes, I like it!", bundle: .module, comment: ""),
                style: .default
            ) { _ in
                self.requestSystemReviewOrFallback()
            }
            
            alert.addAction(dislikeAction)
            alert.addAction(likeAction)
            presentingVC.present(alert, animated: true)
        }
    }
    
    private func showEmailAlert(presentingVC: UIViewController) {
        DispatchQueue.main.async {
            let title = NSLocalizedString("Help us improve the app", bundle: .module, comment: "")
            let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
            
            let laterAction = UIAlertAction(
                title: NSLocalizedString("Maybe later", bundle: .module, comment: ""),
                style: .cancel
            )
            let writeAction = UIAlertAction(
                title: NSLocalizedString("Send feedback", bundle: .module, comment: ""),
                style: .default
            ) { _ in
                self.sendMail(presentingVC: presentingVC)
            }
            
            alert.addAction(laterAction)
            alert.addAction(writeAction)
            presentingVC.present(alert, animated: true)
        }
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

/*
import StoreKit
import MessageUI

public final class ReviewHelper: NSObject {
        
    private var minLaunches: Int
    private var minDays: Int

    public init(minLaunches: Int = 0, minDays: Int = 0) {
        self.minLaunches = minLaunches
        self.minDays = minDays
    }
    
    public func requestImmediately(fromVC: UIViewController? = nil) {
        if let fromVC {
            showAlert(fromVC: fromVC)
        } else {
            ReviewHelper.request()
        }
    }
    
    @discardableResult
    public func requestIf(minLaunches: Int = 0, minDays: Int = 0, fromVC: UIViewController? = nil) -> Bool {
        self.minLaunches = minLaunches
        self.minDays = minDays
        return requestIfNeeded(fromVC: fromVC)
    }
    
    private let ud = UserDefaults.standard
    
    public var launches: Int {
        get { ud.integer(forKey: #function) }
        set(value) { ud.set(value, forKey: #function) }
    }
    
    public var firstLaunchDate: Date? {
        get { ud.object(forKey: #function) as? Date }
        set(value) { ud.set(value, forKey: #function) }
    }
    
    public var lastReviewDate: Date? {
        get { ud.object(forKey: #function) as? Date }
        set(value) { ud.set(value, forKey: #function) }
    }
     
    public var lastReviewVersion: String? {
        get { ud.string(forKey: #function) }
        set(value) { ud.set(value, forKey: #function) }
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

    @discardableResult
    private func requestIfNeeded(fromVC: UIViewController? = nil) -> Bool {
        if firstLaunchDate == nil { firstLaunchDate = Date() }
        launches += 1
        guard isNeeded else { return false }
        lastReviewDate = Date()
        lastReviewVersion = version
        if let fromVC {
            showAlert(fromVC: fromVC)
        } else {
            ReviewHelper.request()
        }
        return true
    }
    
    private func showAlert(fromVC: UIViewController) {
        
        DispatchQueue.main.async { 
            
            let title = NSLocalizedString("Do you like the app?", bundle: .module, comment: "")
            
            let ac = UIAlertController(title: title, message: nil, preferredStyle: .alert)
            
            let noButton = UIAlertAction(title: NSLocalizedString("No", bundle: .module, comment: ""),
                                         style: .default) { _ in
                
            }
            
            let yesButton = UIAlertAction(title: NSLocalizedString("Yes, I like it!", bundle: .module, comment: ""),
                                          style: .default) { _ in
                ReviewHelper.request()
            }
            
            ac.addAction(noButton)
            ac.addAction(yesButton)
            
            fromVC.present(ac, animated: true)
        }
    }
    
    private func showEmailAlert(fromVC: UIViewController) {
        
        DispatchQueue.main.async {
            
            let title = NSLocalizedString("Give us feedback please", bundle: .module, comment: "")
            
            let ac = UIAlertController(title: title, message: nil, preferredStyle: .alert)
            
            let noButton = UIAlertAction(title: NSLocalizedString("Not now", bundle: .module, comment: ""),
                                         style: .default)
            
            let yesButton = UIAlertAction(title: NSLocalizedString("Write feedback", bundle: .module, comment: ""),
                                          style: .default) { _ in
                
            }
            
            ac.addAction(noButton)
            ac.addAction(yesButton)
            
            fromVC.present(ac, animated: true)
        }
    }
    
    private static func request() {
        
        DispatchQueue.main.async {
            #if os(iOS)
            if #available(iOS 14.0, *) {
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    SKStoreReviewController.requestReview(in: scene)
                }
            } else {
                SKStoreReviewController.requestReview()
            }
            #else
            SKStoreReviewController.requestReview()
            #endif
        }
    }
    
    internal var version = Bundle.main.object(
        forInfoDictionaryKey: "CFBundleShortVersionString"
    ) as! String
    
    internal func daysBetween(_ start: Date, _ end: Date) -> Int {
        Calendar.current.dateComponents([.day], from: start, to: end).day!
    }
    
}

// MARK: - Mail

extension ReviewHelper: MFMailComposeViewControllerDelegate {
    
    public func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult, error: Error?) {
        
        controller.dismiss(animated: true, completion: nil)
    }
    
    private func sendMail(fromVC: UIViewController) {
        
        guard MFMailComposeViewController.canSendEmail() else { return }

        let mail = MFMailComposeViewController.getDefault(for: email)
        
        mail.mailComposeDelegate = self
        
        fromVC.present(mail, animated: true)
    }
}
*/
