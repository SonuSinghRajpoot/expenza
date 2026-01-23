# Testing Guide - Expenza Android App

This guide provides comprehensive testing instructions for Phase 5 before production release.

---

## 📱 Phase 5.1: Test Release APK on Physical Device

### Prerequisites

1. **Release APK Built**: Verify the APK exists:
   ```bash
   Test-Path build\app\outputs\flutter-apk\app-release.apk
   ```
   Expected: `True`

2. **Android Device Connected**: 
   - Enable USB debugging on your Android device
   - Connect via USB or use wireless debugging
   - Verify connection: `adb devices`

### Installation Methods

#### Method 1: Using Flutter Install (Recommended)
```bash
flutter install --release
```

#### Method 2: Using ADB Directly
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

#### Method 3: Manual Installation
1. Copy `build/app/outputs/flutter-apk/app-release.apk` to your device
2. Open the APK file on your device
3. Allow installation from unknown sources if prompted
4. Install the app

### Feature Testing Checklist

#### ✅ Core Functionality Tests

**1. Trip Management**
- [ ] Create a new trip
  - [ ] Enter trip name
  - [ ] Set start date
  - [ ] Set end date (optional)
  - [ ] Save trip
- [ ] View trip list
  - [ ] Active trips displayed
  - [ ] Submitted trips displayed
  - [ ] Settled trips displayed
- [ ] Edit trip
  - [ ] Modify trip details
  - [ ] Save changes
- [ ] Submit trip
  - [ ] Trip moves to "Submitted" status
- [ ] Reopen trip
  - [ ] Submitted trip can be reopened
  - [ ] Trip returns to "Active" status

**2. Expense Management**
- [ ] Add expense manually
  - [ ] Select head (Food, Travel, Accommodation, etc.)
  - [ ] Select sub-head
  - [ ] Enter amount
  - [ ] Select date
  - [ ] Enter city
  - [ ] Add notes (optional)
  - [ ] Save expense
- [ ] Add expense with bill image
  - [ ] Take photo with camera
  - [ ] Select from gallery
  - [ ] Scan PDF document
  - [ ] Verify image is attached
- [ ] View expense details
  - [ ] All fields displayed correctly
  - [ ] Bill images viewable
  - [ ] Can zoom images
- [ ] Edit expense
  - [ ] Modify expense details
  - [ ] Update bill images
  - [ ] Save changes
- [ ] Delete expense
  - [ ] Confirm deletion dialog appears
  - [ ] Expense removed
- [ ] Duplicate detection
  - [ ] Create duplicate expense
  - [ ] Warning dialog appears
  - [ ] Can proceed or cancel

**3. AI Bill Scanning (Gemini Integration)**
- [ ] Scan bill with AI
  - [ ] Select bill image
  - [ ] Tap "Analyze with AI"
  - [ ] Loading indicator appears
  - [ ] Form auto-fills with extracted data
- [ ] Verify extracted data accuracy
  - [ ] Amount extracted correctly
  - [ ] Date extracted correctly
  - [ ] Head/sub-head suggested correctly
  - [ ] City extracted (if present)
- [ ] Handle API errors gracefully
  - [ ] Invalid API key shows user-friendly error
  - [ ] Network error shows appropriate message
  - [ ] Rate limit error handled

**4. Advance Management**
- [ ] Add advance
  - [ ] Enter advance amount
  - [ ] Select date
  - [ ] Save advance
- [ ] View advances list
  - [ ] All advances displayed
  - [ ] Total calculated correctly
- [ ] Edit advance
  - [ ] Modify advance details
  - [ ] Save changes
- [ ] Delete advance
  - [ ] Confirm deletion
  - [ ] Advance removed

**5. Export Functionality**
- [ ] Export to PDF
  - [ ] Generate PDF report
  - [ ] PDF opens correctly
  - [ ] All expenses included
  - [ ] Formatting correct
  - [ ] Can share PDF
- [ ] Export to Excel
  - [ ] Generate Excel file
  - [ ] Excel opens correctly
  - [ ] All data present
  - [ ] Can share Excel file

**6. User Profile**
- [ ] View profile
  - [ ] Name displayed
  - [ ] Email displayed
  - [ ] Profile image displayed (if set)
- [ ] Edit profile
  - [ ] Update name
  - [ ] Update email
  - [ ] Change profile image
  - [ ] Save changes
- [ ] Manage Gemini API Keys
  - [ ] Add new API key
  - [ ] Edit existing key
  - [ ] Delete key
  - [ ] Set default key

**7. File Sharing**
- [ ] Share from external app
  - [ ] Share image from gallery
  - [ ] Share PDF from file manager
  - [ ] App receives shared file
  - [ ] Can create expense from shared file

**8. Error Handling**
- [ ] Network errors
  - [ ] Disconnect internet
  - [ ] Try AI scan
  - [ ] User-friendly error message appears
- [ ] File permission errors
  - [ ] Deny camera permission
  - [ ] Appropriate error message
- [ ] Database errors
  - [ ] Simulate database issue
  - [ ] Error handled gracefully

---

## ⚡ Phase 5.2: Performance Testing

### Large Dataset Testing

#### Test 1: Many Expenses
1. Create a trip
2. Add 100+ expenses manually or via script
3. Verify:
   - [ ] App remains responsive
   - [ ] List scrolling smooth
   - [ ] No crashes
   - [ ] Memory usage acceptable (< 200MB)
   - [ ] Export works with large dataset

#### Test 2: Many Trips
1. Create 20+ trips
2. Verify:
   - [ ] Trip list loads quickly
   - [ ] Filtering works
   - [ ] No performance degradation

#### Test 3: Large Images
1. Add expenses with high-resolution images (5MB+)
2. Verify:
   - [ ] Images load without lag
   - [ ] Memory doesn't spike
   - [ ] Can view/zoom images smoothly

#### Test 4: Export Performance
1. Create trip with 50+ expenses
2. Export to PDF
3. Verify:
   - [ ] Export completes in < 30 seconds
   - [ ] PDF file size reasonable (< 10MB)
   - [ ] All data included

### Memory Testing

Use Android Studio Profiler or `adb shell dumpsys meminfo`:

```bash
# Monitor memory usage
adb shell dumpsys meminfo com.fieldexpensemanager.field_expense_manager
```

**Check:**
- [ ] Memory usage stays under 200MB during normal use
- [ ] No memory leaks (memory doesn't continuously grow)
- [ ] Memory released after closing screens

### Battery Testing

**Monitor battery usage:**
- [ ] App doesn't drain battery excessively
- [ ] Background activity minimal
- [ ] No unnecessary wake locks

### Storage Testing

**Check storage usage:**
- [ ] App size reasonable (< 150MB installed)
- [ ] Bill images stored efficiently
- [ ] Database size reasonable
- [ ] Can clear cache if needed

---

## 🐛 Common Issues to Test

### Edge Cases

1. **Date Validation**
   - [ ] Can't set expense date before trip start
   - [ ] Can't set expense date after trip end
   - [ ] Date picker works correctly

2. **Amount Validation**
   - [ ] Can't enter negative amounts
   - [ ] Decimal amounts work (e.g., 123.45)
   - [ ] Very large amounts handled

3. **Empty States**
   - [ ] No trips message displayed
   - [ ] No expenses message displayed
   - [ ] Empty form validation

4. **Network Scenarios**
   - [ ] Offline mode (no internet)
   - [ ] Slow network connection
   - [ ] Intermittent connectivity

5. **Device Rotation**
   - [ ] App handles orientation changes
   - [ ] Forms preserve data
   - [ ] Images display correctly

6. **App Lifecycle**
   - [ ] App resumes correctly after background
   - [ ] Data persists after app restart
   - [ ] No crashes on app close

---

## 📊 Performance Benchmarks

### Target Metrics

| Metric | Target | How to Measure |
|--------|--------|----------------|
| App Launch Time | < 2 seconds | Time from tap to home screen |
| Screen Navigation | < 300ms | Time between screen transitions |
| List Scrolling | 60 FPS | Smooth scrolling, no jank |
| Image Loading | < 1 second | Time to display bill image |
| PDF Export (50 expenses) | < 30 seconds | Time to generate PDF |
| Memory Usage | < 200MB | Peak memory during normal use |
| APK Size | < 120MB | Size of release APK |

---

## 🔍 Testing Tools

### Android Studio Profiler
- Monitor CPU, Memory, Network
- Identify performance bottlenecks

### ADB Commands
```bash
# Check app info
adb shell dumpsys package com.fieldexpensemanager.field_expense_manager

# Monitor logcat
adb logcat | grep -i expenza

# Check memory
adb shell dumpsys meminfo com.fieldexpensemanager.field_expense_manager

# Clear app data (for fresh testing)
adb shell pm clear com.fieldexpensemanager.field_expense_manager
```

### Flutter DevTools
```bash
# Launch DevTools
flutter pub global activate devtools
flutter pub global run devtools
```

---

## ✅ Testing Sign-Off

Before marking Phase 5 as complete, ensure:

- [ ] All core features tested and working
- [ ] No critical bugs found
- [ ] Performance acceptable on target devices
- [ ] Error handling works correctly
- [ ] App stable (no crashes during testing)
- [ ] Memory usage within acceptable limits
- [ ] Export functionality works correctly
- [ ] AI scanning works with valid API key

---

## 📝 Testing Report Template

After completing tests, document:

1. **Test Date**: _______________
2. **Device Model**: _______________
3. **Android Version**: _______________
4. **APK Version**: _______________
5. **Issues Found**: _______________
6. **Performance Notes**: _______________
7. **Recommendations**: _______________

---

**Next Steps**: After completing Phase 5 testing, proceed to Phase 6 (Play Store Preparation).
