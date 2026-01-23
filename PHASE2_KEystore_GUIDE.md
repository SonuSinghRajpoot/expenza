# Phase 2: Android Keystore Setup Guide

This guide will help you complete Step 2.1 and 2.2 of Phase 2.

---

## Step 2.1: Generate Android Keystore

### ⚠️ IMPORTANT
- Do this on a secure machine
- Backup the keystore file in a secure location
- Store passwords in a password manager
- **DO NOT** commit the keystore to git (already in .gitignore)

### Windows Command

Open PowerShell or Command Prompt and run:

```powershell
# Navigate to a secure location (outside the project)
cd C:\Users\YourName\Documents

# Generate keystore
keytool -genkey -v -keystore expenza-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**You'll be prompted for:**
1. **Keystore password** - Enter a strong password (save this!)
2. **Re-enter password** - Confirm the password
3. **First and last name** - Your name or organization name
4. **Organizational unit** - Department/Team (can be blank)
5. **Organization** - Company name
6. **City or locality** - Your city
7. **State or province** - Your state
8. **Two-letter country code** - e.g., US, IN, GB
9. **Confirm** - Type "yes" to confirm
10. **Key password** - Can be same as keystore password (press Enter) or different

**Example:**
```
Enter keystore password: [YourPassword123!]
Re-enter new password: [YourPassword123!]
What is your first and last name?
  [Unknown]: Your Name
What is the name of your organizational unit?
  [Unknown]: Development
What is the name of your organization?
  [Unknown]: Your Company
What is the name of your City or Locality?
  [Unknown]: Your City
What is the name of your State or Province?
  [Unknown]: Your State
What is the two-letter country code for this unit?
  [Unknown]: US
Is CN=Your Name, OU=Development, O=Your Company, L=Your City, ST=Your State, C=US correct?
  [no]: yes
Enter key password for <upload>
        (RETURN if same as keystore password): [Press Enter]
```

### After Generation

The keystore file will be created at: `C:\Users\YourName\Documents\expenza-keystore.jks`

**⚠️ CRITICAL:** 
- Copy this file to a secure backup location (external drive, cloud storage with encryption)
- Store the passwords securely (password manager)
- You'll need this keystore for ALL future releases!

---

## Step 2.2: Create key.properties File

### 1. Copy the example file

In PowerShell (from project root):

```powershell
cd d:\Projects\Expenses
Copy-Item android\key.properties.example android\key.properties
```

### 2. Edit key.properties

Open `android/key.properties` in a text editor and fill in your values:

```properties
storePassword=YourActualKeystorePassword
keyPassword=YourActualKeyPassword
keyAlias=upload
storeFile=C:/Users/YourName/Documents/expenza-keystore.jks
```

**Important Notes:**
- Replace `YourActualKeystorePassword` with the keystore password you entered
- Replace `YourActualKeyPassword` with the key password (or same as keystore if you pressed Enter)
- Replace `C:/Users/YourName/Documents/expenza-keystore.jks` with the actual path to your keystore file
- Use forward slashes `/` in the path, not backslashes `\`
- Use absolute path (full path from C: drive)

**Example:**
```properties
storePassword=MySecurePassword123!
keyPassword=MySecurePassword123!
keyAlias=upload
storeFile=C:/Users/Sonu/Documents/expenza-keystore.jks
```

### 3. Verify .gitignore

The `key.properties` file should already be in `.gitignore`. Verify it won't be committed:

```powershell
git check-ignore android/key.properties
```

If it returns the file path, it's properly ignored. ✅

---

## Step 2.3: Verify Configuration

After creating `key.properties`, verify the setup:

```powershell
# Check if file exists
Test-Path android/key.properties

# Verify it's in .gitignore
git check-ignore android/key.properties
```

---

## Troubleshooting

### Error: "keytool: command not found"
- Make sure Java JDK is installed
- Add Java bin directory to PATH, or use full path:
  ```powershell
  "C:\Program Files\Java\jdk-17\bin\keytool.exe" -genkey ...
  ```

### Error: "Keystore file not found" (during build)
- Check the path in `key.properties` is correct
- Use absolute path (starting with `C:/`)
- Use forward slashes `/` not backslashes `\`
- Make sure the keystore file exists at that location

### Error: "Wrong password"
- Verify passwords in `key.properties` match what you entered
- Check for extra spaces or quotes
- Make sure passwords are on the same line (no line breaks)

---

## Security Checklist

Before proceeding, ensure:
- [ ] Keystore file is backed up securely
- [ ] Passwords are stored in a password manager
- [ ] `key.properties` is in `.gitignore` (verified)
- [ ] Keystore file is NOT in the project directory (or is in .gitignore)
- [ ] You have a secure backup of the keystore

---

## Next Steps

Once `key.properties` is created:
1. ✅ `build.gradle.kts` is already updated
2. Test release build: `flutter build apk --release`
3. Build app bundle: `flutter build appbundle --release`

---

**Need help?** If you encounter any issues, share the error message!
