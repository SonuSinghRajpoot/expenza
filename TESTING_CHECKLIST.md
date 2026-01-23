# Testing Checklist - Expenza v1.0.0+1

**Test Date**: _______________  
**Tester**: _______________  
**Device Model**: _______________  
**Android Version**: _______________  
**APK Size**: 109.6 MB

---

## 📱 Installation & Setup

- [ ] Release APK installed successfully
- [ ] App launches without crashes
- [ ] App icon displays correctly
- [ ] Splash screen appears (if applicable)
- [ ] Initial screen loads correctly

---

## ✅ Core Features Testing

### Trip Management

- [ ] **Create Trip**
  - [ ] Trip name field accepts input
  - [ ] Start date picker works
  - [ ] End date picker works (optional)
  - [ ] Save button creates trip
  - [ ] Trip appears in trip list

- [ ] **View Trip List**
  - [ ] Active trips section displays
  - [ ] Submitted trips section displays
  - [ ] Settled trips section displays
  - [ ] Trip cards show correct information
  - [ ] Empty state message shows when no trips

- [ ] **Edit Trip**
  - [ ] Edit button opens form
  - [ ] Can modify trip name
  - [ ] Can modify dates
  - [ ] Save changes works
  - [ ] Changes reflect in trip list

- [ ] **Submit Trip**
  - [ ] Submit button works
  - [ ] Trip moves to "Submitted" status
  - [ ] Can reopen submitted trip

- [ ] **Reopen Trip**
  - [ ] Reopen button works
  - [ ] Trip returns to "Active" status

### Expense Management

- [ ] **Add Expense (Manual)**
  - [ ] Head dropdown works (Food, Travel, etc.)
  - [ ] Sub-head dropdown populates correctly
  - [ ] Amount field accepts decimal values
  - [ ] Date picker works
  - [ ] City field accepts input
  - [ ] To City field works (for travel)
  - [ ] Notes field accepts text
  - [ ] Save button creates expense
  - [ ] Expense appears in list

- [ ] **Add Expense (With Bill Image)**
  - [ ] Camera button opens camera
  - [ ] Gallery button opens gallery
  - [ ] PDF button works
  - [ ] Image displays in form
  - [ ] Can add multiple images
  - [ ] Can remove images
  - [ ] Images saved with expense

- [ ] **View Expense Details**
  - [ ] All fields display correctly
  - [ ] Bill images display
  - [ ] Can zoom images
  - [ ] Can view full-screen images
  - [ ] Navigation works

- [ ] **Edit Expense**
  - [ ] Edit button opens form
  - [ ] Pre-filled data correct
  - [ ] Can modify all fields
  - [ ] Can update bill images
  - [ ] Save changes works

- [ ] **Delete Expense**
  - [ ] Delete button shows confirmation
  - [ ] Cancel works
  - [ ] Confirm removes expense
  - [ ] Bill images cleaned up

- [ ] **Duplicate Detection**
  - [ ] Creating duplicate shows warning
  - [ ] Can proceed anyway
  - [ ] Can cancel

### AI Bill Scanning

- [ ] **Gemini API Integration**
  - [ ] API key configured
  - [ ] "Analyze with AI" button works
  - [ ] Loading indicator appears
  - [ ] Form auto-fills with extracted data
  - [ ] Amount extracted correctly
  - [ ] Date extracted correctly
  - [ ] Head/sub-head suggested
  - [ ] City extracted (if present)

- [ ] **Error Handling (AI)**
  - [ ] Invalid API key shows friendly error
  - [ ] Network error handled gracefully
  - [ ] Rate limit error handled
  - [ ] Empty response handled
  - [ ] Malformed response handled

### Advance Management

- [ ] **Add Advance**
  - [ ] Add advance button works
  - [ ] Amount field works
  - [ ] Date picker works
  - [ ] Save creates advance
  - [ ] Advance appears in list

- [ ] **View Advances**
  - [ ] All advances displayed
  - [ ] Total calculated correctly
  - [ ] List updates when advances added/removed

- [ ] **Edit Advance**
  - [ ] Edit button works
  - [ ] Can modify amount
  - [ ] Can modify date
  - [ ] Save changes works

- [ ] **Delete Advance**
  - [ ] Delete button shows confirmation
  - [ ] Confirm removes advance
  - [ ] Total updates correctly

### Export Functionality

- [ ] **Export to PDF**
  - [ ] Export button works
  - [ ] PDF generates successfully
  - [ ] PDF opens correctly
  - [ ] All expenses included
  - [ ] Formatting correct
  - [ ] Can share PDF
  - [ ] File size reasonable

- [ ] **Export to Excel**
  - [ ] Export button works
  - [ ] Excel file generates
  - [ ] Excel opens correctly
  - [ ] All data present
  - [ ] Formatting correct
  - [ ] Can share Excel file

### User Profile

- [ ] **View Profile**
  - [ ] Profile screen loads
  - [ ] Name displays
  - [ ] Email displays
  - [ ] Profile image displays (if set)

- [ ] **Edit Profile**
  - [ ] Edit button opens dialog
  - [ ] Can update name
  - [ ] Can update email
  - [ ] Can change profile image
  - [ ] Save changes works
  - [ ] Changes reflect immediately

- [ ] **Manage Gemini Keys**
  - [ ] Manage keys button works
  - [ ] Can add new API key
  - [ ] Can edit existing key
  - [ ] Can delete key
  - [ ] Can set default key
  - [ ] Validation works

### File Sharing

- [ ] **Share from External App**
  - [ ] Share image from gallery
  - [ ] App receives shared file
  - [ ] Can create expense from shared file
  - [ ] Share PDF from file manager
  - [ ] PDF processed correctly

---

## ⚡ Performance Testing

### Large Dataset Tests

- [ ] **100+ Expenses**
  - [ ] Create 100 expenses
  - [ ] App remains responsive
  - [ ] List scrolling smooth (60 FPS)
  - [ ] No crashes
  - [ ] Memory usage < 200MB
  - [ ] Export works with 100 expenses

- [ ] **20+ Trips**
  - [ ] Create 20 trips
  - [ ] Trip list loads quickly (< 2 seconds)
  - [ ] Filtering works
  - [ ] No performance degradation

- [ ] **Large Images**
  - [ ] Add expense with 5MB+ image
  - [ ] Image loads without lag
  - [ ] Memory doesn't spike
  - [ ] Can zoom smoothly

- [ ] **Export Performance**
  - [ ] Export 50 expenses to PDF
  - [ ] Completes in < 30 seconds
  - [ ] PDF size < 10MB
  - [ ] All data included

### Memory & Battery

- [ ] **Memory Usage**
  - [ ] Peak memory < 200MB
  - [ ] No memory leaks
  - [ ] Memory released after navigation

- [ ] **Battery Usage**
  - [ ] No excessive battery drain
  - [ ] Background activity minimal
  - [ ] No unnecessary wake locks

---

## 🐛 Error Handling Tests

- [ ] **Network Errors**
  - [ ] Disconnect internet
  - [ ] Try AI scan
  - [ ] User-friendly error message
  - [ ] App doesn't crash

- [ ] **File Permission Errors**
  - [ ] Deny camera permission
  - [ ] Appropriate error message
  - [ ] Can grant permission later

- [ ] **Database Errors**
  - [ ] App handles gracefully
  - [ ] Error message user-friendly
  - [ ] No data loss

- [ ] **API Errors**
  - [ ] Invalid API key handled
  - [ ] Rate limit handled
  - [ ] Network timeout handled
  - [ ] All show friendly messages

---

## 🔄 Edge Cases

- [ ] **Date Validation**
  - [ ] Can't set expense date before trip start
  - [ ] Can't set expense date after trip end
  - [ ] Date picker works correctly

- [ ] **Amount Validation**
  - [ ] Can't enter negative amounts
  - [ ] Decimal amounts work (123.45)
  - [ ] Very large amounts handled

- [ ] **Empty States**
  - [ ] No trips message
  - [ ] No expenses message
  - [ ] Empty form validation

- [ ] **Device Rotation**
  - [ ] App handles orientation changes
  - [ ] Forms preserve data
  - [ ] Images display correctly

- [ ] **App Lifecycle**
  - [ ] App resumes after background
  - [ ] Data persists after restart
  - [ ] No crashes on close

---

## 📊 Performance Benchmarks

| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| App Launch Time | < 2s | _____ | [ ] |
| Screen Navigation | < 300ms | _____ | [ ] |
| List Scrolling | 60 FPS | _____ | [ ] |
| Image Loading | < 1s | _____ | [ ] |
| PDF Export (50) | < 30s | _____ | [ ] |
| Memory Usage | < 200MB | _____ | [ ] |
| APK Size | < 120MB | 109.6MB | ✅ |

---

## 🐛 Issues Found

### Critical Issues
1. _______________________________________
2. _______________________________________
3. _______________________________________

### High Priority Issues
1. _______________________________________
2. _______________________________________
3. _______________________________________

### Low Priority Issues
1. _______________________________________
2. _______________________________________
3. _______________________________________

---

## ✅ Testing Sign-Off

- [ ] All core features tested
- [ ] No critical bugs found
- [ ] Performance acceptable
- [ ] Error handling works
- [ ] App stable (no crashes)
- [ ] Ready for production

**Tester Signature**: _______________  
**Date**: _______________

---

**Next**: After completing this checklist, proceed to Phase 6 (Play Store Preparation).
