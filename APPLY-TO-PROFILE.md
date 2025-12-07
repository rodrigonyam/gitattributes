# Apply .gitattributes to All Repositories

This PowerShell script helps you apply the `.gitattributes` configuration to all your GitHub repositories to improve language statistics display on your profile.

## 🚀 Quick Setup

### Option 1: Manual Application (Recommended for a few repos)

1. **Clone this repository** to get the `.gitattributes` file:
   ```powershell
   git clone https://github.com/rodrigonyam/gitattributes.git
   ```

2. **Copy to your repositories**:
   ```powershell
   # Navigate to your target repository
   cd path/to/your/repository
   
   # Copy the .gitattributes file
   Copy-Item "path/to/gitattributes/.gitattributes" -Destination "./.gitattributes"
   
   # Commit and push
   git add .gitattributes
   git commit -m "Add .gitattributes for improved language detection"
   git push
   ```

### Option 2: Bulk Application (For many repositories)

Use the PowerShell script below to apply to multiple repositories at once.

## 📝 Prerequisites

- **GitHub CLI installed**: `winget install GitHub.cli`
- **Git configured** with your credentials
- **PowerShell 5.1+** (Windows default)

## 🔧 Bulk Application Script

Save this as `apply-gitattributes.ps1`:

```powershell
# GitHub Username
$GitHubUsername = "rodrigonyam"

# Path to your .gitattributes template
$GitAttributesSource = ".\\.gitattributes"

# Directory to clone repositories (temporary)
$WorkDir = "temp-repos"

# Ensure GitHub CLI is authenticated
Write-Host "🔐 Checking GitHub CLI authentication..." -ForegroundColor Yellow
try {
    $authStatus = gh auth status 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Please authenticate with GitHub CLI first:" -ForegroundColor Red
        Write-Host "   gh auth login" -ForegroundColor Cyan
        exit 1
    }
    Write-Host "✅ GitHub CLI authenticated" -ForegroundColor Green
}
catch {
    Write-Host "❌ GitHub CLI not found. Install with: winget install GitHub.cli" -ForegroundColor Red
    exit 1
}

# Check if .gitattributes source exists
if (-not (Test-Path $GitAttributesSource)) {
    Write-Host "❌ .gitattributes file not found at: $GitAttributesSource" -ForegroundColor Red
    Write-Host "   Make sure you're running this script from the gitattributes repository directory" -ForegroundColor Yellow
    exit 1
}

# Create working directory
if (Test-Path $WorkDir) {
    Remove-Item $WorkDir -Recurse -Force
}
New-Item -ItemType Directory -Path $WorkDir | Out-Null
Set-Location $WorkDir

Write-Host "🔍 Fetching your repositories..." -ForegroundColor Yellow

# Get all user repositories
try {
    $repos = gh repo list $GitHubUsername --limit 100 --json name,isPrivate,isFork | ConvertFrom-Json
    $publicRepos = $repos | Where-Object { -not $_.isPrivate -and -not $_.isFork }
    
    Write-Host "📊 Found $($repos.Count) total repositories" -ForegroundColor Cyan
    Write-Host "📊 Found $($publicRepos.Count) public non-fork repositories" -ForegroundColor Cyan
}
catch {
    Write-Host "❌ Error fetching repositories: $_" -ForegroundColor Red
    exit 1
}

$successCount = 0
$skipCount = 0
$errorCount = 0

foreach ($repo in $publicRepos) {
    $repoName = $repo.name
    Write-Host "`n🔄 Processing repository: $repoName" -ForegroundColor Yellow
    
    try {
        # Clone repository
        Write-Host "   📥 Cloning..." -ForegroundColor Gray
        gh repo clone "$GitHubUsername/$repoName" 2>$null
        
        if (-not (Test-Path $repoName)) {
            Write-Host "   ⚠️  Failed to clone $repoName - skipping" -ForegroundColor Yellow
            $skipCount++
            continue
        }
        
        Set-Location $repoName
        
        # Check if .gitattributes already exists
        if (Test-Path ".gitattributes") {
            Write-Host "   ℹ️  .gitattributes already exists - skipping" -ForegroundColor Blue
            $skipCount++
            Set-Location ..
            continue
        }
        
        # Copy .gitattributes
        Copy-Item "../$GitAttributesSource" -Destination "./.gitattributes"
        
        # Check if there are changes to commit
        $gitStatus = git status --porcelain
        if (-not $gitStatus) {
            Write-Host "   ℹ️  No changes to commit - skipping" -ForegroundColor Blue
            $skipCount++
            Set-Location ..
            continue
        }
        
        # Add and commit
        git add .gitattributes
        git commit -m "Add .gitattributes for improved language detection" 2>$null
        
        if ($LASTEXITCODE -eq 0) {
            # Push changes
            Write-Host "   📤 Pushing changes..." -ForegroundColor Gray
            git push 2>$null
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "   ✅ Successfully applied to $repoName" -ForegroundColor Green
                $successCount++
            } else {
                Write-Host "   ❌ Failed to push to $repoName" -ForegroundColor Red
                $errorCount++
            }
        } else {
            Write-Host "   ❌ Failed to commit to $repoName" -ForegroundColor Red
            $errorCount++
        }
        
        Set-Location ..
    }
    catch {
        Write-Host "   ❌ Error processing $repoName : $_" -ForegroundColor Red
        $errorCount++
        if (Test-Path $repoName) {
            Set-Location ..
        }
    }
}

# Clean up
Set-Location ..
Remove-Item $WorkDir -Recurse -Force

# Summary
Write-Host "`n📊 SUMMARY" -ForegroundColor Cyan
Write-Host "✅ Successfully applied: $successCount repositories" -ForegroundColor Green
Write-Host "⚠️  Skipped: $skipCount repositories" -ForegroundColor Yellow
Write-Host "❌ Errors: $errorCount repositories" -ForegroundColor Red

Write-Host "`n🔄 Note: GitHub may take a few minutes to re-analyze repositories and update language statistics." -ForegroundColor Yellow
Write-Host "📈 Your profile language statistics should update within 24 hours." -ForegroundColor Cyan
```

## 🎯 Usage Instructions

1. **Navigate to this directory**:
   ```powershell
   cd path/to/gitattributes
   ```

2. **Run the script**:
   ```powershell
   # Save the script above as apply-gitattributes.ps1
   .\apply-gitattributes.ps1
   ```

3. **Monitor progress** - the script will:
   - Clone each repository temporarily
   - Copy the `.gitattributes` file
   - Commit and push the changes
   - Clean up temporary files

## ⚠️ Important Notes

### What This Does
- **Applies language detection rules** to all your public repositories
- **Excludes generated/config files** from language statistics
- **Improves accuracy** of your GitHub profile language breakdown
- **Skips repositories** that already have `.gitattributes`

### What To Expect
- **Immediate**: Files are added to repositories
- **Within hours**: GitHub re-analyzes repositories
- **Within 24 hours**: Profile language statistics update

### Safety Features
- **Non-destructive**: Only adds `.gitattributes`, doesn't modify existing files
- **Skip existing**: Won't overwrite existing `.gitattributes` files
- **Error handling**: Continues processing even if individual repositories fail
- **Cleanup**: Removes temporary files after processing

## 🔍 Verification

After running the script, you can verify the changes:

1. **Check individual repositories** on GitHub for the new `.gitattributes` file
2. **Monitor your profile** at `https://github.com/rodrigonyam` for updated language stats
3. **Use GitHub API** to check language breakdown:
   ```powershell
   # Check a specific repository
   gh api repos/rodrigonyam/REPO-NAME/languages
   ```

## 🛠️ Troubleshooting

### Common Issues
- **Authentication Error**: Run `gh auth login`
- **Permission Error**: Ensure you have write access to repositories
- **Network Issues**: Check internet connection and GitHub status

### Manual Verification
If the script fails for some repositories, you can manually apply:
```powershell
git clone https://github.com/rodrigonyam/REPO-NAME
cd REPO-NAME
copy ..\\.gitattributes .
git add .gitattributes
git commit -m "Add .gitattributes for improved language detection"
git push
```

## 📈 Expected Impact

After applying `.gitattributes` to your repositories, you should see:

- **More accurate language percentages** on your GitHub profile
- **Exclusion of configuration files** from language stats
- **Proper categorization** of frontend vs backend code
- **Cleaner repository language breakdowns**

The language statistics on your profile will better reflect your actual coding work rather than including configuration files, documentation, and generated code.