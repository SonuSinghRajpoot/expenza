# Git Push Guide - Expenza

This guide will help you push your code to a remote git repository (GitHub, GitLab, etc.).

## Current Status
- ✅ Local git repository initialized
- ✅ Initial commit created
- ⚠️ No remote repository configured yet

---

## Step 1: Create a Remote Repository (if you don't have one)

### Option A: GitHub
1. Go to [GitHub.com](https://github.com) and sign in
2. Click the **"+"** icon in the top right → **"New repository"**
3. Repository name: `expenza` (or your preferred name)
4. Description: "Field Expense Manager - Android App"
5. Choose **Private** or **Public**
6. **DO NOT** initialize with README, .gitignore, or license (we already have these)
7. Click **"Create repository"**
8. Copy the repository URL (e.g., `https://github.com/yourusername/expenza.git`)

### Option B: GitLab
1. Go to [GitLab.com](https://gitlab.com) and sign in
2. Click **"New project"** → **"Create blank project"**
3. Project name: `expenza`
4. Choose visibility (Private/Public)
5. **DO NOT** initialize with README
6. Click **"Create project"**
7. Copy the repository URL

### Option C: Bitbucket
1. Go to [Bitbucket.org](https://bitbucket.org) and sign in
2. Click **"Create"** → **"Repository"**
3. Repository name: `expenza`
4. Choose **Private** or **Public**
5. Click **"Create repository"**
6. Copy the repository URL

---

## Step 2: Add Remote Repository

Once you have your repository URL, run:

```bash
# Replace <your-repository-url> with your actual URL
git remote add origin <your-repository-url>
```

**Examples:**
```bash
# HTTPS (GitHub)
git remote add origin https://github.com/yourusername/expenza.git

# SSH (GitHub)
git remote add origin git@github.com:yourusername/expenza.git

# HTTPS (GitLab)
git remote add origin https://gitlab.com/yourusername/expenza.git
```

---

## Step 3: Verify Remote

Check that the remote was added correctly:

```bash
git remote -v
```

You should see:
```
origin  https://github.com/yourusername/expenza.git (fetch)
origin  https://github.com/yourusername/expenza.git (push)
```

---

## Step 4: Push to Remote

### First Push (set upstream)

```bash
git push -u origin master
```

**Note:** If your default branch is `main` instead of `master`:
```bash
git push -u origin master:main
# or rename your local branch first:
git branch -M main
git push -u origin main
```

### Future Pushes

After the first push, you can simply use:
```bash
git push
```

---

## Troubleshooting

### Error: "Repository not found"
- Check that the repository URL is correct
- Verify you have access to the repository
- Make sure you're authenticated (GitHub/GitLab credentials)

### Error: "Authentication failed"
- For HTTPS: You may need a Personal Access Token instead of password
- For SSH: Make sure your SSH key is added to your account
- See authentication setup below

### Error: "Branch name mismatch"
- If remote uses `main` but local uses `master`:
  ```bash
  git branch -M main
  git push -u origin main
  ```

---

## Authentication Setup

### GitHub - Personal Access Token (HTTPS)
1. Go to GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Generate new token (classic)
3. Select scopes: `repo` (full control)
4. Copy the token
5. Use token as password when pushing

### SSH Key Setup (Recommended)
1. Generate SSH key:
   ```bash
   ssh-keygen -t ed25519 -C "your_email@example.com"
   ```
2. Add to SSH agent:
   ```bash
   eval "$(ssh-agent -s)"
   ssh-add ~/.ssh/id_ed25519
   ```
3. Copy public key:
   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```
4. Add to GitHub/GitLab: Settings → SSH Keys → Add new key

---

## Quick Commands Summary

```bash
# Check status
git status

# Add remote (one time)
git remote add origin <your-repo-url>

# Verify remote
git remote -v

# Push (first time)
git push -u origin master

# Future pushes
git push
```

---

## What Gets Pushed?

✅ **Will be pushed:**
- All source code
- Documentation files
- Configuration files
- Assets (fonts, icons)

❌ **Will NOT be pushed** (already in .gitignore):
- `android/key.properties` (keystore credentials)
- `*.keystore`, `*.jks` files
- Build artifacts
- Temporary files
- IDE-specific files

---

**Need help?** If you encounter any errors, share the error message and I'll help you resolve it!
