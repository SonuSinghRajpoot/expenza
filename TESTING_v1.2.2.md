# Expenza 1.2.2 — Device testing checklist

Build under test: **Expenza Debug** (separate app next to your real Expenza; app id `…field_expense_manager.debug`).
It is labelled **version 1.1.9** on purpose, so the update check finds GitHub's v1.2.0 and the update flow can be tested.
Debug builds run slower than release builds. Judge behaviour, not speed.

---

## 0. Setup (once)
- [ ] Open **Expenza Debug**. Allow the permissions it asks for.
- [ ] Profile → Gemini: check an API key is present. It may be restored automatically from your real app's backup; if not, add one.
- [ ] Create a trip, set it **Active**, and add cities like **Delhi, Mumbai, Bangalore**. After adding, "Bangalore" should show as **Bengaluru** (CTY-2).
- [ ] Keep handy: a flight ticket PDF, a train ticket, a restaurant bill photo, a hotel bill PDF with 3+ pages, a software invoice (Microsoft 365, Google Workspace, Adobe…), and a PDF someone sent you on WhatsApp.

> Avoid editing your profile or Gemini keys in the debug app. Both apps write the same account backup file in `Documents/Expenza`.

---

## A. Sharing a file into the app (your bug "a")
In the Android share sheet, always pick **Expenza Debug**.

| # | Steps | Expected | ✔ |
|---|---|---|---|
| A1 | Close the app fully (swipe it away in Recents). Share a PDF to it. | The **first** share opens the Add Expense options (or the trip picker if there are several active trips). Repeat 3 times; it should work every time. (SHR-1/2) | [ ] |
| A2 | With the app in the background, share a PDF. | The Add Expense options open. | [ ] |
| A3 | Choose **AI-Scan Receipt** after sharing. | The form opens **straight away**, then a spinner shows while the PDF is converted and analysed. (SHR-3) | [ ] |
| A4 | Share a PDF **from WhatsApp**. | AI scan works. Evidence shows page image(s), not a broken file. (SHR-6) | [ ] |
| A5 | Share, finish or cancel, then swipe the app away and reopen it **from Recents**. | No old share pops up again. (SHR-4) | [ ] |
| A6 | Share two files quickly one after the other. | The dialogs appear **one after another**, not stacked on top of each other. (SHR-4) | [ ] |
| A7 | Turn **App Lock on** (Profile). Close the app fully, then share a PDF. | The fingerprint/PIN prompt appears first; the share dialog appears **after** unlocking. | [ ] |
| A8 | Same as A7, but cancel the fingerprint prompt, then tap **Unlock Expenza**. | The share dialog appears after unlocking. | [ ] |
| A9 | Fresh launch of the app via a share (app fully closed). | **No** permission prompts this time, only the share flow. Open the app normally later: any remaining permission prompt appears then, after unlock. (SHR-5) | [ ] |
| A10 | Close the app fully and share. Watch the AI-Scan option. | It may show **"Checking Gemini key…"** with a small spinner for a moment, then become active. The buttons below don't jump. (SHR-7) | [ ] |
| A11 | Set all trips to non-Active, then share. | Message: "No active trips found to add expense to." | [ ] |

## B. Cities (your bug "b")
| # | Steps | Expected | ✔ |
|---|---|---|---|
| B1 | AI-scan a **flight ticket**. | From/To are **city names** (e.g. Delhi → Mumbai), never "IGI Airport" or "Terminal 1D". (CTY-1/3) | [ ] |
| B2 | AI-scan a **train ticket** (station codes like NDLS, CSMT). | From/To are the cities (Delhi, Mumbai). | [ ] |
| B3 | AI-scan a **restaurant bill** that has a full address. | The City field shows just the city, or is **empty** with a hint like *AI read "Sector 18" – not a recognised city. Please pick one.* | [ ] |
| B4 | Tap the City field. | The list is a **short scrolling panel**, not full screen. Trip cities come first. Typing filters the list. | [ ] |
| B5 | Type **Bombay** in City and save. Open the expense. | Saved as **Mumbai**. | [ ] |
| B6 | Type an unlisted town (e.g. **Jaitpur**) and save. | A dialog asks **"Use anyway?"**. **Change** returns to the form; **Use anyway** saves it as typed. (CTY-4) | [ ] |
| B7 | Add the same expense twice: once with city "New Delhi", once with "Delhi" (same head, sub-head, amount and date). | The second save shows the **Duplicate Expense?** warning. (CTY-4) | [ ] |
| B8 | After a few AI scans, open Edit Trip. | The trip's city list contains **no junk values** (no airports, areas or PIN codes). (CTY-2) | [ ] |

## C. Remarks (your bug "c")
| # | Steps | Expected | ✔ |
|---|---|---|---|
| C1 | AI-scan the **same bill 3 times** (cancel the form each time). | The Notes text has the **same format** every time, e.g. "Delhi to Mumbai flight ticket for 1 person". (RMK-1/3) | [ ] |
| C2 | In a new expense, change the sub-head, cities or Pax. | Notes **update automatically**; the helper text says "Filled automatically from the details above". (RMK-5) | [ ] |
| C3 | Type your own notes, then change the sub-head. | Your notes are **kept**. Clear the notes, change a field: the auto remark comes back. | [ ] |
| C4 | Edit an older expense that has hand-written notes. | Notes are **not** overwritten. | [ ] |
| C5 | AI-scan a **hotel bill with 3+ pages** where the total is on page 3. | Amount = the final total from the later page. (RMK-2) | [ ] |
| C6 | Check remark formats: Cab within one city / Hotel / Lunch / Event fee. | "Cab in Pune for 2 persons" / "Hotel stay in Jaipur for 2 persons" / "Lunch in Pune for 3 persons" / "Event Fee in Delhi". | [ ] |

## D. Form
| # | Steps | Expected | ✔ |
|---|---|---|---|
| D1 | Share a **food bill** and use AI scan (AI picks e.g. Food → Lunch). Tap **Save**. | Saves without a false **"Required"** on Sub Head. (GEN-2) | [ ] |
| D2 | AI result where the sub-head doesn't fit the head. | Sub Head is empty and must be picked; the remark doesn't mention a wrong sub-head. (RMK-3) | [ ] |

## E. New: Subscription head
| # | Steps | Expected | ✔ |
|---|---|---|---|
| E1 | Add Expense → **Subscription** → **Software / App**. | The form shows **City (Optional)** and no Pax field. Saving with an empty city works. | [ ] |
| E2 | Look at the notes and the trip list row. | Notes say "Software / App subscription". The row shows no stray "•" for the empty city. | [ ] |
| E3 | AI-scan a Microsoft 365 / Google Workspace / Adobe invoice. | Head = **Subscription**, Sub Head = **Software / App**. | [ ] |
| E4 | Export the trip as PDF and Excel. | Subscription appears in the summaries (teal bar in the PDF). | [ ] |

## F. New: Icons
| # | Steps | Expected | ✔ |
|---|---|---|---|
| F1 | Add Expense dialog: tap each head and look at the sub-heads. | All icons are the same outlined style. Bike = motorbike, Flight = plane, Hotel = service bell, Event Fee = ticket, Event head = calendar. | [ ] |
| F2 | An "Others" expense in the trip list. | Shows its head's icon (e.g. luggage for Travel), not "⋯". | [ ] |

## G. New: App updates from GitHub
| # | Steps | Expected | ✔ |
|---|---|---|---|
| G1 | Open the app normally (from the launcher) and wait ~5 seconds on the main screen. | An **"Update available"** dialog appears for **v1.2.0**, showing release notes, file name and size. | [ ] |
| G1b | Tap **Later**, swipe the app away in Recents, and open it again. | The dialog appears again: the check runs on **every launch**. | [ ] |
| G1c | Swipe the app away, then **share a PDF** to Expenza Debug. Finish or cancel the share. | **No** update dialog during or after that share. (Launches that come from a share skip the check.) | [ ] |
| G1d | With the app in the background, share a PDF to it. | The share flow is never interrupted by the update dialog. | [ ] |
| G2 | Tap **Later**. Then go to **Profile → App Updates → Check for updates**. | The dialog appears again (manual checks always run). | [ ] |
| G3 | Tap **Update**. | A progress bar downloads `app-arm64-v8a-release.apk` (~46 MB). Android may ask you to allow **"Install unknown apps"** for Expenza Debug. Then the Android installer opens. **Tap Cancel in the installer.** (Installing would target your real app, and Android blocks it anyway, because v1.2.0 is older than your 1.2.1.) | [ ] |
| G3a | With **at least one Active trip**, tap **Update** in the update dialog. | A **"Back up your reports first"** warning lists your active trips with when their Excel/PDF were last saved, and offers **Generate reports**, **Update without backup** and **Cancel**. | [ ] |
| G3b | Tap **Generate reports**. | A progress bar counts the files; then "Saved N files to Internal storage › Expenza". Check that the `.xlsx` and `.pdf` files exist in that folder. **Continue update** then starts the download. | [ ] |
| G3c | Set all trips to submitted (none Active), with at least one submitted trip that has never been exported. Tap **Update**. | The warning says there are no active trips and lists only the submitted trips **missing** an Excel or PDF report. | [ ] |
| G3d | Same as G3c, but every submitted trip already has both reports. Tap **Update**. | No warning; the download starts straight away. | [ ] |
| G3e | In the warning, tap **Cancel**. | Back to the update dialog; nothing is downloaded. | [ ] |
| G4 | Check for updates again → **Skip version**. Swipe the app away and reopen it. | No automatic dialog for v1.2.0 on any launch. A manual check still shows it. | [ ] |
| G5 | Turn on airplane mode → Check for updates. | Message: "Could not reach GitHub. Check your internet connection." | [ ] |

## H. Quick regression
- [ ] Add, edit and delete expenses normally (manual entry, camera scan, gallery, PDF upload).
- [ ] Trip PDF and Excel exports open and look right.
- [ ] App Lock on/off still works; your **real Expenza** app is unchanged.

---
Report any failure with its **ID** (e.g. "B3 failed"), what you shared or scanned, and a screenshot.
