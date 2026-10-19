# Kharcha – Indian expense tracker for iPhone

Tracks bank, card and UPI payments from SMS, totals your monthly spending by category, and suggests where to save.

## Run it in Xcode (needs a Mac)
1. Copy this whole folder to a Mac with Xcode 16 or newer.
2. Double-click `Kharcha.xcodeproj`.
3. Pick an iPhone simulator at the top and press **⌘R**.
4. In the app, go to **Settings → Load sample data** to see the dashboard and insights filled in.
5. Try **+ → Paste SMS** with a message like:
   `Rs.249.00 debited from A/c XX4521 on 05-10-26 to VPA swiggy@icici. UPI Ref 628374659201`

## Run it on your iPhone (free)
1. Connect the iPhone with a cable and select it at the top of Xcode.
2. Click the **Kharcha** project → **Signing & Capabilities** → **Team** → add your Apple ID.
3. If Xcode says the bundle ID is taken, change `com.vikram.kharcha` to something unique.
4. On the iPhone, turn on **Settings → Privacy & Security → Developer Mode**, then press **⌘R**.
5. The first time, trust the app under **Settings → General → VPN & Device Management**.

Apps installed with a free Apple ID stop working after 7 days. Press ⌘R again to reinstall.

## Automatic SMS tracking
iOS does not allow apps to read SMS. Kharcha uses a Shortcuts automation instead. The in-app guide is under
**Settings → Set up auto-tracking**.
