// The Swift Programming Language
// https://docs.swift.org/swift-book

import StoreKit

public final class AppReview {
    
    static let shared = AppReview()
    
    public let minLaunches: Int
    public let minDays: Int

    public init(minLaunches: Int = 0, minDays: Int = 0) {
        self.minLaunches = minLaunches
        self.minDays = minDays
    }
    
    public static func requestImmediately(fromVC: UIViewController? = nil) {
        if let fromVC {
            shared.showAlert(fromVC: fromVC)
        } else {
            shared.request()
        }
    }
    
    @discardableResult
    public static func requestIf(launches: Int = 0, days: Int = 0, fromVC: UIViewController? = nil) -> Bool {
        shared.requestIfNeeded(fromVC: fromVC)
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
    public func requestIfNeeded(fromVC: UIViewController? = nil) -> Bool {
        if firstLaunchDate == nil { firstLaunchDate = Date() }
        launches += 1
        guard isNeeded else { return false }
        lastReviewDate = Date()
        lastReviewVersion = version
        if let fromVC {
            showAlert(fromVC: fromVC)
        } else {
            request()
        }
        return true
    }
    
    private func showAlert(fromVC: UIViewController) {
        
        let title = NSLocalizedString("Do you like the app?", bundle: .module, comment: "")

        let ac = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        
        let noButton = UIAlertAction(title: NSLocalizedString("No", bundle: .module, comment: ""),
                                     style: .default)
        
        let yesButton = UIAlertAction(title: NSLocalizedString("Yes, I like it!", bundle: .module, comment: ""),
                                      style: .default) { [weak self] _ in
            self?.request()
        }
        
        ac.addAction(noButton)
        ac.addAction(yesButton)
        
        fromVC.present(ac, animated: true)
    }
    
    private func request() {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
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
