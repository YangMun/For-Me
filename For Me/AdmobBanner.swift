import SwiftUI
import GoogleMobileAds
import UIKit

// MARK: - AdMob 관리자 클래스
class AdMobManager: NSObject {
    static let shared = AdMobManager()
    
    // 광고 모니터링을 위한 변수 추가
    private var adRequestCount: [String: Int] = ["banner": 0, "interstitial": 0, "rewarded": 0]
    private var adShowCount: [String: Int] = ["banner": 0, "interstitial": 0, "rewarded": 0]
    private var lastRequestTime: [String: Date] = [:]
    
    // Info.plist에서 광고 ID 가져오기
    private(set) var homeBannerID: String
    private(set) var speechAIBannerID: String
    private(set) var plusMikeBannerID: String
    
    // 광고 객체들
    private var homeBanner: GADBannerView?
    private var interstitialAd: GADInterstitialAd?
    private var rewardedAd: GADRewardedAd?
    
    // 광고 로드 상태
    @Published var isHomeBannerReady: Bool = false
    @Published var isInterstitialReady: Bool = false
    @Published var isRewardedAdReady: Bool = false
    
    // 광고 초기화 상태 추가
    private var isInitialized = false
    
    // 배너 광고의 첫 노출 여부를 추적하기 위한 변수 추가
    private var isFirstBannerShow = false
    
    private override init() {
        // Info.plist에서 광고 ID 로드
        guard let homeBannerID = Bundle.main.object(forInfoDictionaryKey: "GADHomeBannerID") as? String,
              let speechAIBannerID = Bundle.main.object(forInfoDictionaryKey: "GADSpeechAIBannerID") as? String,
              let plusMikeBannerID = Bundle.main.object(forInfoDictionaryKey: "GADPlusMikeBannerID") as? String else {
            fatalError("AdMob 광고 ID를 Info.plist에서 찾을 수 없습니다.")
        }
        
        self.homeBannerID = homeBannerID
        self.speechAIBannerID = speechAIBannerID
        self.plusMikeBannerID = plusMikeBannerID
        
        super.init()
        
        // 앱 시작 시 미리 광고 로드하기
        initialize()
        
        // 테스트 기기 설정 (개발 중에 사용)
        #if DEBUG
        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = ["ccc9fc71b7fa90e988fdd5a87cf9e2f3"]
        #endif
    }
    
    // 광고 요청 추적 함수
    private func trackAdRequest(type: String) {
        adRequestCount[type, default: 0] += 1
        lastRequestTime[type] = Date()
        print("[\(type)] 광고 요청 - 총 요청 수: \(adRequestCount[type, default: 0])")
        printAdStats(type: type)
    }
    
    // 광고 노출 추적 함수
    private func trackAdShow(type: String) {
        // 배너 광고의 경우 첫 노출만 카운트
        if type == "banner" {
            if !isFirstBannerShow {
                adShowCount[type, default: 0] += 1
                isFirstBannerShow = true
                
                if let lastRequest = lastRequestTime[type] {
                    let timeInterval = Date().timeIntervalSince(lastRequest)
                    print("[\(type)] 광고 노출 - 총 노출 수: \(adShowCount[type, default: 0])")
                    print("[\(type)] 요청부터 노출까지 소요 시간: \(String(format: "%.2f", timeInterval))초")
                }
                printAdStats(type: type)
            }
        } else {
            // 다른 광고 타입은 기존대로 처리
            adShowCount[type, default: 0] += 1
            if let lastRequest = lastRequestTime[type] {
                let timeInterval = Date().timeIntervalSince(lastRequest)
                print("[\(type)] 광고 노출 - 총 노출 수: \(adShowCount[type, default: 0])")
                print("[\(type)] 요청부터 노출까지 소요 시간: \(String(format: "%.2f", timeInterval))초")
            }
            printAdStats(type: type)
        }
    }
    
    // 광고 통계 출력 함수
    private func printAdStats(type: String) {
        let requests = adRequestCount[type, default: 0]
        let shows = adShowCount[type, default: 0]
        let ratio = requests > 0 ? Double(shows) / Double(requests) * 100 : 0
        print("[\(type)] 광고 통계:")
        print("- 총 요청 수: \(requests)")
        print("- 총 노출 수: \(shows)")
        print("- 노출률: \(String(format: "%.2f", ratio))%")
        print("------------------------")
    }
    
    // 초기화 함수 수정
    func initialize() {
        guard !isInitialized else { return }
        isInitialized = true
        
        // 전면 광고와 리워드 광고만 미리 로드
        loadInterstitialAd()
        loadRewardedAd()
    }
    
    // MARK: - 배너 광고 (홈 화면)
    func loadHomeBanner() -> GADBannerView {
        if let existingBanner = homeBanner {
            return existingBanner
        }
        
        trackAdRequest(type: "banner")
        let banner = GADBannerView(adSize: GADAdSizeBanner)
        banner.adUnitID = homeBannerID
        banner.rootViewController = UIApplication.shared.windows.first?.rootViewController
        banner.delegate = self
        banner.load(GADRequest())
        homeBanner = banner
        return banner
    }
    
    // MARK: - 전면 광고 (SpeechAI)
    func loadInterstitialAd(completion: (() -> Void)? = nil) {
        trackAdRequest(type: "interstitial")
        isInterstitialReady = false
        
        GADInterstitialAd.load(withAdUnitID: speechAIBannerID, request: GADRequest()) { [weak self] ad, error in
            guard let self = self else { return }
            
            if let error = error {
                // print("전면 광고 로드 실패: \(error.localizedDescription)")
                return
            }
            
            self.interstitialAd = ad
            self.interstitialAd?.fullScreenContentDelegate = self
            self.isInterstitialReady = true
            completion?()
        }
    }
    
    func showInterstitialAd() -> Bool {
        guard let interstitialAd = interstitialAd else {
            return false
        }
        
        // 루트 뷰 컨트롤러 가져오기
        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
            return false
        }
        
        // 현재 표시 중인 가장 상위 뷰 컨트롤러 찾기
        var topViewController = rootViewController
        while let presentedVC = topViewController.presentedViewController {
            topViewController = presentedVC
        }
        
        // 이미 뷰를 표시하고 있는지 확인
        guard !topViewController.isBeingPresented && !topViewController.isBeingDismissed else {
            // print("뷰 컨트롤러가 이미 표시 중이거나 해제 중입니다.")
            return false
        }
        
        // 안전하게 메인 스레드에서 실행
        DispatchQueue.main.async {
            interstitialAd.present(fromRootViewController: topViewController)
        }
        return true
    }
    
    // MARK: - 리워드 광고 (PlusMike)
    func loadRewardedAd(completion: (() -> Void)? = nil) {
        trackAdRequest(type: "rewarded")
        isRewardedAdReady = false
        
        GADRewardedAd.load(withAdUnitID: plusMikeBannerID, request: GADRequest()) { [weak self] ad, error in
            guard let self = self else { return }
            
            if let error = error {
                // print("리워드 광고 로드 실패: \(error.localizedDescription)")
                return
            }
            
            self.rewardedAd = ad
            self.rewardedAd?.fullScreenContentDelegate = self
            self.isRewardedAdReady = true
            completion?()
        }
    }
    
    func showRewardedAd(completion: @escaping (Bool) -> Void) -> Bool {
        guard let rewardedAd = rewardedAd else {
            return false
        }
        
        // 루트 뷰 컨트롤러 가져오기
        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
            return false
        }
        
        // 현재 표시 중인 가장 상위 뷰 컨트롤러 찾기
        var topViewController = rootViewController
        while let presentedVC = topViewController.presentedViewController {
            topViewController = presentedVC
        }
        
        // 이미 뷰를 표시하고 있는지 확인
        guard !topViewController.isBeingPresented && !topViewController.isBeingDismissed else {
            // print("뷰 컨트롤러가 이미 표시 중이거나 해제 중입니다.")
            return false
        }
        
        // 안전하게 메인 스레드에서 실행
        DispatchQueue.main.async {
            rewardedAd.present(fromRootViewController: topViewController) { [weak self] in
                // 보상 지급
                completion(true)
                
                // 다음 광고 미리 로드
                self?.loadRewardedAd()
            }
        }
        return true
    }
}

// MARK: - 배너 광고 델리게이트
extension AdMobManager: GADBannerViewDelegate {
    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        trackAdShow(type: "banner")
        isHomeBannerReady = true
    }
    
    // 배너 광고 실패 시 첫 노출 상태 초기화
    func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        print("배너 광고 로드 실패: \(error.localizedDescription)")
        isHomeBannerReady = false
        isFirstBannerShow = false  // 실패 시 첫 노출 상태 초기화
        
        // 실패시 재시도 간격을 3분으로 증가
        DispatchQueue.main.asyncAfter(deadline: .now() + 180) { [weak self] in
            self?.homeBanner?.load(GADRequest())
        }
    }
}

// MARK: - 전면/리워드 광고 델리게이트
extension AdMobManager: GADFullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        if ad === interstitialAd {
            trackAdShow(type: "interstitial")
            loadInterstitialAd()
            NotificationCenter.default.post(name: NSNotification.Name("AdDismissed"), object: nil)
        } else if ad === rewardedAd {
            trackAdShow(type: "rewarded")
            loadRewardedAd()
        }
    }
    
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("전체화면 광고 표시 실패: \(error.localizedDescription)")
        
        // 실패시 재시도 간격을 3분으로 증가
        DispatchQueue.main.asyncAfter(deadline: .now() + 180) { [weak self] in
            if ad === self?.interstitialAd {
                self?.loadInterstitialAd()
            } else if ad === self?.rewardedAd {
                self?.loadRewardedAd()
            }
        }
    }
}

// MARK: - SwiftUI 배너 뷰
struct HomeBannerView: UIViewRepresentable {
    func makeUIView(context: Context) -> GADBannerView {
        return AdMobManager.shared.loadHomeBanner()
    }
    
    func updateUIView(_ uiView: GADBannerView, context: Context) {
        // 필요한 경우 업데이트 로직
    }
}

// MARK: - 전면 광고 SwiftUI 래퍼
struct InterstitialAdView: View {
    @State private var isAdPresented = false
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button(action: {
            if AdMobManager.shared.isInterstitialReady {
                isAdPresented = AdMobManager.shared.showInterstitialAd()
                action?()
            } else {
                // 광고가 준비되지 않은 경우 로드 후 표시 시도
                AdMobManager.shared.loadInterstitialAd {
                    isAdPresented = AdMobManager.shared.showInterstitialAd()
                    action?()
                }
            }
        }) {
            // 버튼 콘텐츠 (필요에 따라 커스터마이징)
            Text("전면 광고 보기")
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(8)
        }
    }
}

// MARK: - 리워드 광고 SwiftUI 래퍼
struct RewardedAdButton: View {
    var rewardCompletion: (Bool) -> Void
    var buttonText: String
    
    var body: some View {
        Button(action: {
            if AdMobManager.shared.isRewardedAdReady {
                let _ = AdMobManager.shared.showRewardedAd(completion: rewardCompletion)
            } else {
                // 광고가 준비되지 않은 경우 로드 후 표시 시도
                AdMobManager.shared.loadRewardedAd {
                    let _ = AdMobManager.shared.showRewardedAd(completion: rewardCompletion)
                }
            }
        }) {
            Text(buttonText)
                .foregroundColor(.white)
                .padding()
                .background(AdMobManager.shared.isRewardedAdReady ? Color.green : Color.gray)
                .cornerRadius(8)
        }
        .disabled(!AdMobManager.shared.isRewardedAdReady)
    }
}

// 앱 초기화 함수 수정
func initializeAdMob() {
    GADMobileAds.sharedInstance().start { status in
        // AdMob 초기화 완료 후 광고 매니저 초기화
        AdMobManager.shared.initialize()
    }
}
