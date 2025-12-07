# ============================================================================
# Apply .gitattributes to All GitHub Repositories
# ============================================================================
# This script applies the .gitattributes configuration to all your public
# GitHub repositories to improve language statistics on your profile.
#
# Author: GitHub Copilot
# Repository: https://github.com/rodrigonyam/gitattributes
# ============================================================================

param(
    [string]$GitHubUsername = "rodrigonyam",
    [string]$GitAttributesSource = ".\.gitattributes",
    [string]$WorkDir = "temp-repos",
    [switch]$DryRun = $false,
    [switch]$IncludePrivate = $false,
    [switch]$IncludeForks = $false
)

# Colors for output
$Colors = @{
    Success = "Green"
    Warning = "Yellow" 
    Error = "Red"
    Info = "Cyan"
    Gray = "Gray"
    Blue = "Blue"
}

function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Colors[$Color]
}

function Show-Header {
    Write-ColorOutput "`n============================================================================" "Cyan"
    Write-ColorOutput "  🔧 GitHub Repository .gitattributes Bulk Application Tool" "Cyan"
    Write-ColorOutput "============================================================================`n" "Cyan"
    
    if ($DryRun) {
        Write-ColorOutput "🔍 DRY RUN MODE - No changes will be made`n" "Warning"
    }
}

function Test-Prerequisites {
    Write-ColorOutput "🔐 Checking prerequisites..." "Info"
    
    # Check GitHub CLI
    try {
        $ghVersion = gh --version 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "GitHub CLI not found"
        }
        Write-ColorOutput "✅ GitHub CLI found" "Success"
    }
    catch {
        Write-ColorOutput "❌ GitHub CLI not found. Install with:" "Error"
        Write-ColorOutput "   winget install GitHub.cli" "Gray"
        return $false
    }
    
    # Check authentication
    try {
        $authStatus = gh auth status 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-ColorOutput "❌ Please authenticate with GitHub CLI:" "Error"
            Write-ColorOutput "   gh auth login" "Gray"
            return $false
        }
        Write-ColorOutput "✅ GitHub CLI authenticated" "Success"
    }
    catch {
        Write-ColorOutput "❌ GitHub CLI authentication failed" "Error"
        return $false
    }
    
    # Check .gitattributes source file
    if (-not (Test-Path $GitAttributesSource)) {
        Write-ColorOutput "❌ .gitattributes file not found at: $GitAttributesSource" "Error"
        Write-ColorOutput "   Make sure you're in the correct directory" "Gray"
        return $false
    }
    Write-ColorOutput "✅ .gitattributes source file found" "Success"
    
    # Check Git
    try {
        $gitVersion = git --version 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "Git not found"
        }
        Write-ColorOutput "✅ Git found" "Success"
    }
    catch {
        Write-ColorOutput "❌ Git not found. Please install Git first." "Error"
        return $false
    }
    
    return $true
}

function Get-Repositories {
    Write-ColorOutput "`n🔍 Fetching repositories for user: $GitHubUsername" "Info"
    
    try {
        $repoQuery = @("--limit", "100", "--json", "name,isPrivate,isFork,pushedAt")
        
        $allRepos = gh repo list $GitHubUsername @repoQuery | ConvertFrom-Json
        
        # Filter repositories based on parameters
        $filteredRepos = $allRepos | Where-Object {
            $includeRepo = $true
            
            if (-not $IncludePrivate -and $_.isPrivate) {
                $includeRepo = $false
            }
            
            if (-not $IncludeForks -and $_.isFork) {
                $includeRepo = $false
            }
            
            return $includeRepo
        }
        
        # Sort by most recently pushed
        $sortedRepos = $filteredRepos | Sort-Object pushedAt -Descending
        
        Write-ColorOutput "📊 Total repositories: $($allRepos.Count)" "Info"
        Write-ColorOutput "📊 Filtered repositories: $($sortedRepos.Count)" "Info"
        Write-ColorOutput "   - Public: $($sortedRepos | Where-Object { -not $_.isPrivate } | Measure-Object | Select-Object -ExpandProperty Count)" "Gray"
        Write-ColorOutput "   - Private: $($sortedRepos | Where-Object { $_.isPrivate } | Measure-Object | Select-Object -ExpandProperty Count)" "Gray"
        Write-ColorOutput "   - Forks: $($allRepos | Where-Object { $_.isFork } | Measure-Object | Select-Object -ExpandProperty Count)" "Gray"
        
        return $sortedRepos
    }
    catch {
        Write-ColorOutput "❌ Error fetching repositories: $_" "Error"
        return @()
    }
}

function Initialize-WorkDirectory {
    if (Test-Path $WorkDir) {
        Write-ColorOutput "🧹 Cleaning existing work directory..." "Gray"
        Remove-Item $WorkDir -Recurse -Force
    }
    
    New-Item -ItemType Directory -Path $WorkDir | Out-Null
    return (Resolve-Path $WorkDir).Path
}

function Process-Repository {
    param([object]$repo, [string]$workPath, [string]$sourcePath)
    
    $repoName = $repo.name
    $repoPath = Join-Path $workPath $repoName
    $results = @{
        Name = $repoName
        Status = "Unknown"
        Message = ""
    }
    
    try {
        Write-ColorOutput "`n🔄 Processing: $repoName" "Info"
        
        # Clone repository
        Write-ColorOutput "   📥 Cloning repository..." "Gray"
        if (-not $DryRun) {
            Push-Location $workPath
            gh repo clone "$GitHubUsername/$repoName" 2>$null
            Pop-Location
            
            if (-not (Test-Path $repoPath)) {
                $results.Status = "Skipped"
                $results.Message = "Failed to clone repository"
                return $results
            }
        }
        
        if (-not $DryRun) {
            Push-Location $repoPath
        }
        
        # Check if .gitattributes already exists
        $gitattributesPath = if ($DryRun) { "mock-path" } else { ".gitattributes" }
        if (-not $DryRun -and (Test-Path $gitattributesPath)) {
            Write-ColorOutput "   ℹ️  .gitattributes already exists" "Blue"
            $results.Status = "Skipped"
            $results.Message = ".gitattributes already exists"
            Pop-Location
            return $results
        }
        
        # Copy .gitattributes file
        Write-ColorOutput "   📋 Copying .gitattributes..." "Gray"
        if (-not $DryRun) {
            Copy-Item $sourcePath -Destination $gitattributesPath
        }
        
        # Check for changes
        if (-not $DryRun) {
            $gitStatus = git status --porcelain 2>$null
            if (-not $gitStatus) {
                Write-ColorOutput "   ℹ️  No changes detected" "Blue"
                $results.Status = "Skipped"
                $results.Message = "No changes to commit"
                Pop-Location
                return $results
            }
        }
        
        # Add and commit changes
        Write-ColorOutput "   💾 Committing changes..." "Gray"
        if (-not $DryRun) {
            git add .gitattributes 2>$null
            git commit -m "Add .gitattributes for improved language detection`n`nThis file configures GitHub Linguist to properly categorize files and exclude generated/configuration files from language statistics." 2>$null
            
            if ($LASTEXITCODE -ne 0) {
                $results.Status = "Error"
                $results.Message = "Failed to commit changes"
                Pop-Location
                return $results
            }
        }
        
        # Push changes
        Write-ColorOutput "   📤 Pushing to GitHub..." "Gray"
        if (-not $DryRun) {
            git push origin 2>$null
            
            if ($LASTEXITCODE -eq 0) {
                Write-ColorOutput "   ✅ Successfully applied to $repoName" "Success"
                $results.Status = "Success"
                $results.Message = "Successfully applied .gitattributes"
            } else {
                Write-ColorOutput "   ❌ Failed to push changes" "Error"
                $results.Status = "Error" 
                $results.Message = "Failed to push to remote"
            }
            Pop-Location
        } else {
            Write-ColorOutput "   ✅ Would apply .gitattributes to $repoName" "Success"
            $results.Status = "Success"
            $results.Message = "Would apply .gitattributes (dry run)"
        }
        
        return $results
    }
    catch {
        Write-ColorOutput "   ❌ Error processing repository: $_" "Error"
        $results.Status = "Error"
        $results.Message = "Exception: $_"
        
        if (-not $DryRun -and (Get-Location).Path -ne (Get-Location -PSProvider FileSystem).ProviderPath) {
            Pop-Location
        }
        
        return $results
    }
}

function Show-Summary {
    param([array]$results)
    
    $successCount = ($results | Where-Object { $_.Status -eq "Success" }).Count
    $skipCount = ($results | Where-Object { $_.Status -eq "Skipped" }).Count  
    $errorCount = ($results | Where-Object { $_.Status -eq "Error" }).Count
    
    Write-ColorOutput "`n============================================================================" "Cyan"
    Write-ColorOutput "📊 EXECUTION SUMMARY" "Cyan"
    Write-ColorOutput "============================================================================" "Cyan"
    Write-ColorOutput "✅ Successful: $successCount repositories" "Success"
    Write-ColorOutput "⚠️  Skipped: $skipCount repositories" "Warning"
    Write-ColorOutput "❌ Errors: $errorCount repositories" "Error"
    Write-ColorOutput "📈 Total processed: $($results.Count) repositories`n" "Info"
    
    # Show detailed results
    if ($errorCount -gt 0) {
        Write-ColorOutput "❌ ERRORS:" "Error"
        $results | Where-Object { $_.Status -eq "Error" } | ForEach-Object {
            Write-ColorOutput "   - $($_.Name): $($_.Message)" "Gray"
        }
        Write-Host ""
    }
    
    if ($skipCount -gt 0) {
        Write-ColorOutput "⚠️  SKIPPED:" "Warning"
        $results | Where-Object { $_.Status -eq "Skipped" } | ForEach-Object {
            Write-ColorOutput "   - $($_.Name): $($_.Message)" "Gray"
        }
        Write-Host ""
    }
    
    if (-not $DryRun -and $successCount -gt 0) {
        Write-ColorOutput "🔄 Note: GitHub may take a few minutes to re-analyze repositories." "Warning"
        Write-ColorOutput "📈 Language statistics should update within 24 hours." "Info"
        Write-ColorOutput "🔗 Check your profile at: https://github.com/$GitHubUsername" "Info"
    }
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Show-Header
    
    # Check prerequisites
    if (-not (Test-Prerequisites)) {
        exit 1
    }
    
    # Get repositories
    $repositories = Get-Repositories
    if ($repositories.Count -eq 0) {
        Write-ColorOutput "❌ No repositories found to process." "Error"
        exit 1
    }
    
    # Initialize work directory
    if (-not $DryRun) {
        $workPath = Initialize-WorkDirectory
        $sourcePath = Resolve-Path $GitAttributesSource
    } else {
        $workPath = "dry-run-path"
        $sourcePath = "dry-run-source"
    }
    
    # Process each repository
    $results = @()
    $current = 0
    
    foreach ($repo in $repositories) {
        $current++
        Write-ColorOutput "[$current/$($repositories.Count)]" "Gray"
        
        $result = Process-Repository -repo $repo -workPath $workPath -sourcePath $sourcePath
        $results += $result
        
        # Small delay to avoid rate limiting
        if (-not $DryRun) {
            Start-Sleep -Milliseconds 500
        }
    }
    
    # Clean up
    if (-not $DryRun -and (Test-Path $WorkDir)) {
        Write-ColorOutput "`n🧹 Cleaning up temporary files..." "Gray"
        Remove-Item $WorkDir -Recurse -Force
    }
    
    # Show summary
    Show-Summary -results $results
    
} catch {
    Write-ColorOutput "❌ Unexpected error: $_" "Error"
    exit 1
}