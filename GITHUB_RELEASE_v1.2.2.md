# Expenza v1.2.2

**Version:** `1.2.2` (build 9)

Expenza 1.2.2 makes sharing receipts into the app reliable, keeps city names and expense remarks consistent, and adds in-app updates.

## What's new

- **In-app updates.** Expenza checks for a new version each time you open it, and you can check any time from **Profile → App Updates → Check for updates**. It shows what's new, downloads the right file for your phone and opens the installer. Before updating, it offers to save the Excel and PDF reports of your trips.
- **Subscription expenses.** A new **Subscription** category (with **Software / App**) for recurring software and app plans. City is optional for subscriptions.
- **Clearer icons** for every expense category and sub-category.

## Improvements

- **Sharing files into Expenza works on the first try.** Sharing a PDF or photo from WhatsApp, Gmail or Files now opens Add Expense every time, including when the app was closed or locked. Shares are handled one at a time, and reopening the app from Recents no longer brings back an old share.
- **PDFs from WhatsApp and other apps** are recognised even when the file name doesn't end in ".pdf".
- **Valid Indian city names.** AI Scan now fills From/To and City with real city names, for example "Delhi" instead of "IGI Airport Terminal 1D", and maps old names such as Bombay → Mumbai and Gurgaon → Gurugram. If the bill shows something that isn't a city, the field is left for you to pick, with a hint showing what was read.
- **Searchable city list** with every major Indian city, shown as a compact scrolling panel. Unlisted towns can still be used after a quick confirmation.
- **Consistent remarks.** Notes are written in one fixed format from the expense details, e.g. "Delhi to Mumbai flight ticket for 1 person". They update as you change the details, and stop updating once you type your own.
- **Better AI Scan of multi-page documents.** All pages of tickets and hotel bills (up to 6) are read, so totals on later pages are picked up.
- **Duplicate check** now recognises the same city written differently ("New Delhi" / "Delhi").

## Fixes

- Saving an AI-scanned expense no longer shows a false "Required" error on Sub Head.
- The AI-Scan option no longer appears late and shifts the buttons when the app opens.
- Permission prompts no longer interrupt the fingerprint/PIN unlock or a file being shared.
- Toggle switches are now clearly visible when turned off.

## Installing

### ⚠️ If you have v1.2.0 or v1.2.1 installed, read this first
Those two versions were signed with the wrong key, so **1.2.2 cannot install over them** (Android shows "App not installed"). You need to uninstall the old version first, and **uninstalling deletes your trips, expenses and bill images on the phone.** Your profile and Gemini keys are restored automatically.

Before uninstalling:
1. Open each trip and export its **Excel** and **PDF** reports (open the trip → ⋮ menu → **Export Excel**, then **Export PDF**). They are saved in **Internal storage › Expenza** and are not deleted.
2. Copy those files somewhere safe (Google Drive, email, PC) if you want an extra copy.
3. Uninstall Expenza, then install 1.2.2 from the files below.

### If you have v1.1.0 or earlier
Just install 1.2.2 over it. Your data is kept.

From 1.2.2 onward, updates install over the existing app, and Expenza tells you when a new version is available.

### Which file to download
- **app-arm64-v8a-release.apk**: most phones from the last few years (recommended)
- **app-armeabi-v7a-release.apk**: older 32-bit phones
- **app-x86_64-release.apk**: emulators and x86 devices

Requires Android 7.0 or later. If Android asks, allow your browser or file manager to "install unknown apps".
