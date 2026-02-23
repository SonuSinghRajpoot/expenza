# Testing Roadmap – Changes (Feb 23, 2026)

Test plan for all changes made today.

---

## 1. Delete Trip (No Expenses Only)

**Changes:** Delete trip option added under the three-dot menu in trip details, below "Edit Trip", with confirmation dialog. Only shown when the trip has no expenses.

| # | Test Case | Steps | Expected Result |
|---|-----------|--------|-----------------|
| 1.1 | Delete option hidden when trip has expenses | Open a trip that has ≥1 expense → Tap three-dot menu | "Delete Trip" is not visible |
| 1.2 | Delete option hidden when trip has advances only | Create trip with no expenses, add advance → Tap three-dot menu | "Delete Trip" is not visible |
| 1.3 | Delete option visible when trip has no expenses | Create new trip (no expenses, no advances) → Open trip → Tap three-dot menu | "Delete Trip" appears below "Edit Trip" |
| 1.4 | Confirmation dialog appears | Select "Delete Trip" | Confirmation dialog with trip name and "Cancel" / "Delete" buttons |
| 1.5 | Cancel does nothing | Tap "Cancel" in confirmation | Dialog closes, trip unchanged |
| 1.6 | Delete removes trip | Tap "Delete" in confirmation | Trip is deleted, navigates to dashboard, snackbar: "Trip deleted successfully" |

---

## 2. Expense Position After Edit

**Changes:** Editing and saving an expense no longer moves it to the bottom of the list; it keeps its position.

| # | Test Case | Steps | Expected Result |
|---|-----------|--------|-----------------|
| 2.1 | Position preserved when editing amount | Create 3+ expenses in order A, B, C → Edit B (e.g. amount) → Save | B remains in the middle, order stays A, B, C |
| 2.2 | Position preserved when editing category | Edit any expense and change head/subHead → Save | Expense keeps its position |
| 2.3 | Position preserved when editing date | Edit expense date → Save | Position unchanged |

---

## 3. Expense Type Icons

**Changes:** Icons for specific sub-heads (e.g. Flight, Bike, Bus, Fuel, Train, Auto, E-Rickshaw, TV Rent) and all other sub-heads via `expense_icons.dart`.

| # | Test Case | Steps | Expected Result |
|---|-----------|--------|-----------------|
| 3.1 | Travel sub-head icons | Add expense for: Flight, Bike, Bus, Fuel, Train, Auto, E-Rickshaw | Correct icons (flight, bike, bus, gas, train, taxi, e-rickshaw) in trip details |
| 3.2 | Event TV Rent icon | Add Event → TV Rent expense | TV icon in trip details |
| 3.3 | Accommodation icons | Add Hotel, PG, Guest House expenses | Hotel, apartment, night-shelter icons |
| 3.4 | Food icons | Add Breakfast, Lunch, Dinner, Snacks expenses | Correct icons for each |
| 3.5 | Event sub-head icons | Add Event Fee, Equipments Rent, Printing Fee, Courier, Stationary, Gift Item | Appropriate icons for each |
| 3.6 | Icons in Add Expense dialog | Open Add Expense → Select any head → Sub-categories | Sub-category icons shown next to each option |

---

## 4. New Sub-Head Options

**Changes:** New sub-heads: Travel – Auto, E-Rickshaw; Event – TV Rent.

| # | Test Case | Steps | Expected Result |
|---|-----------|--------|-----------------|
| 4.1 | Auto sub-head | Add Expense → Travel → Select "Auto" | Expense saves with subHead Auto and taxi icon |
| 4.2 | E-Rickshaw sub-head | Add Expense → Travel → Select "E-Rickshaw" | Expense saves with subHead E-Rickshaw and e-rickshaw icon |
| 4.3 | TV Rent sub-head | Add Expense → Event → Select "TV Rent" | Expense saves with subHead TV Rent and TV icon |

---

## 5. Add Expense Dialog Overflow

**Changes:** Dialog wrapped in `ConstrainedBox` + `SingleChildScrollView` so content scrolls instead of overflowing.

| # | Test Case | Steps | Expected Result |
|---|-----------|--------|-----------------|
| 5.1 | No overflow when Event selected | Add Expense → Select Event | No "BOTTOM OVERFLOWED" error, sub-categories visible and scrollable |
| 5.2 | Scrolling works | Add Expense → Select Event → Scroll down | All sub-categories reachable, Back/Cancel visible |
| 5.3 | Other heads still work | Add Expense → Select Travel, Food, etc. | Layout correct, no overflow |

---

## 6. App Version in Profile

**Changes:** Real app version from `pubspec.yaml`, optional rollout timestamp, link to GitHub releases.

| # | Test Case | Steps | Expected Result |
|---|-----------|--------|-----------------|
| 6.1 | Version matches pubspec | Profile → Scroll to bottom | Shows "App Version X.Y.Z+N" (e.g. 1.0.3+5) |
| 6.2 | Rollout timestamp (when passed) | Build with `--dart-define=BUILD_TIMESTAMP=...` | "Rolled out: &lt;timestamp&gt;" shown under version |
| 6.3 | Tapping opens GitHub | Profile → Tap version text | Opens GitHub releases page in browser |

---

## Summary Checklist

- [ ] Delete trip (1.1–1.6)
- [ ] Expense edit position (2.1–2.3)
- [ ] Expense icons (3.1–3.6)
- [ ] New sub-heads (4.1–4.3)
- [ ] Add Expense overflow (5.1–5.3)
- [ ] App version in profile (6.1–6.3)

---

## Build Commands Reference

```powershell
# Debug build + install to device
flutter build apk --debug
flutter install -d RZCY917QXQA --debug

# Release build with rollout timestamp
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
flutter build apk --release --dart-define=BUILD_TIMESTAMP=$timestamp
```
