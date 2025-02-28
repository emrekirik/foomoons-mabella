import Cocoa
import FlutterMacOS
import FirebaseCore
import FirebaseMessaging
import UserNotifications

@main
class AppDelegate: FlutterAppDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {
  override func applicationDidFinishLaunching(_ notification: Notification) {
    FirebaseApp.configure()
    print("Firebase configured")
    
    // UNUserNotificationCenter delegate'i ayarla
    let center = UNUserNotificationCenter.current()
    center.delegate = self
    
    // Bildirim izinlerini iste
    center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
      if granted {
        print("Notification permission granted")
        DispatchQueue.main.async {
          NSApplication.shared.registerForRemoteNotifications()
        }
      } else {
        print("Notification permission denied")
      }
    }
    
    // Messaging delegate'i ayarla
    Messaging.messaging().delegate = self
    print("Messaging delegate set")
    
    super.applicationDidFinishLaunching(notification)
  }
  
  // APNS token alındığında
  override func application(_ application: NSApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    print("Successfully registered for notifications!")
    
    let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
    let token = tokenParts.joined()
    print("Device Token: \(token)")
    
    Messaging.messaging().apnsToken = deviceToken
  }
  
  // APNS token alınamazsa
  override func application(_ application: NSApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("Failed to register for notifications: \(error.localizedDescription)")
  }
}

// MessagingDelegate için extension
extension AppDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("Firebase registration token: \(String(describing: fcmToken))")
    let dataDict: [String: String] = ["token": fcmToken ?? ""]
    NotificationCenter.default.post(
      name: Notification.Name("FCMToken"),
      object: nil,
      userInfo: dataDict
    )
  }
}
