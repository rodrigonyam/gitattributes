# .gitattributes Configuration

This repository contains a comprehensive `.gitattributes` file for controlling GitHub's Linguist language detection and repository statistics.

## 📋 What is .gitattributes?

The `.gitattributes` file allows you to control how Git and GitHub's Linguist handle files in your repository. It's particularly useful for:

- **Language Statistics**: Control which files are included in GitHub's language breakdown
- **File Classification**: Mark files as documentation, generated code, or vendored dependencies
- **Repository Accuracy**: Ensure your repository's language statistics reflect your actual work

## 🎯 Supported Languages

This configuration supports detection and proper categorization for:

### Frontend Languages
- **HTML** (`.html`, `.htm`, `.xhtml`)
- **CSS** (`.css`, `.scss`, `.sass`, `.less`)
- **JavaScript** (`.js`, `.mjs`, `.jsx`)
- **TypeScript** (`.ts`, `.tsx`)

### Backend Languages
- **C#** (`.cs`, `.csx`, `.cake`)
- **Python** (`.py`, `.pyx`, `.pyw`)
- **Java** (`.java`)
- **C/C++** (`.c`, `.cpp`, `.h`, `.hpp`, etc.)
- **Go** (`.go`)
- **Rust** (`.rs`)
- **PHP** (`.php`, `.phtml`, etc.)
- **Ruby** (`.rb`, `.rake`, `.gemspec`)
- **Kotlin** (`.kt`, `.kts`)
- **Scala** (`.scala`, `.sc`)
- **Swift** (`.swift`)
- **Dart** (`.dart`)
- **Elixir** (`.ex`, `.exs`)
- **Erlang** (`.erl`, `.hrl`)
- **Haskell** (`.hs`, `.lhs`)
- **F#** (`.fs`, `.fsx`, `.fsi`)
- **Visual Basic** (`.vb`, `.vbs`)

## 🚫 Excluded from Language Statistics

### Documentation Files
- Markdown files (`.md`, `.markdown`)
- Text files (`.txt`)
- Documentation folders (`docs/`, `documentation/`)
- Project files (`README*`, `CHANGELOG*`, `LICENSE*`)

### Generated & Build Files
- Minified files (`.min.js`, `.min.css`)
- Build outputs (`dist/`, `build/`, `out/`, `target/`, `bin/`, `obj/`)
- Compiled files (`.class`, `.jar`, `.exe`, `.dll`, `.so`)
- Lock files (`package-lock.json`, `yarn.lock`, `Cargo.lock`, etc.)

### Configuration Files
- JSON, XML, YAML configuration files
- Package manager files (`pom.xml`, `build.gradle`, `composer.json`, etc.)
- Project configuration files (`.csproj`, `.sln`, `requirements.txt`, etc.)

### Vendored Code
- Third-party dependencies (`vendor/`, `node_modules/`, `packages/`)
- External libraries and frameworks

## 🔧 Usage

1. **Copy the `.gitattributes` file** to the root of your repository
2. **Commit the file** to your repository:
   ```bash
   git add .gitattributes
   git commit -m "Add .gitattributes for language detection"
   git push
   ```
3. **Wait for GitHub to re-analyze** your repository (may take a few minutes)

## 📊 How It Works

### Linguist Attributes

- `linguist-detectable=true`: Include file in language statistics
- `linguist-detectable=false`: Exclude file from language statistics
- `linguist-documentation=true`: Mark as documentation (excluded from stats)
- `linguist-generated=true`: Mark as generated code (excluded from stats)
- `linguist-vendored=true`: Mark as third-party code (excluded from stats)
- `linguist-language=Language`: Force a specific language classification

### Rule Precedence

Rules in `.gitattributes` are applied from top to bottom, with later rules taking precedence over earlier ones.

## 🎨 Customization

### To Include Test Files in Statistics
Uncomment the test file exclusion rules in the `.gitattributes` file:
```gitattributes
# Remove the # to exclude test files from statistics
test/** linguist-detectable=false
tests/** linguist-detectable=false
*.test.js linguist-detectable=false
```

### To Add New Languages
Add new file extensions following this pattern:
```gitattributes
# New Language Files
*.newext linguist-detectable=true
```

### To Exclude Specific Folders
Add folder exclusion rules:
```gitattributes
# Exclude specific folder
my-folder/** linguist-detectable=false
```

## 🔍 Verification

After applying the `.gitattributes` file, you can verify the language detection:

1. **GitHub Web Interface**: Check your repository's language bar
2. **GitHub API**: Query the languages endpoint:
   ```
   https://api.github.com/repos/[username]/[repository]/languages
   ```
3. **Local Testing**: Use the `github-linguist` gem locally

## 📚 Resources

- [GitHub Linguist Documentation](https://github.com/github/linguist)
- [Git Attributes Documentation](https://git-scm.com/docs/gitattributes)
- [GitHub Language Detection](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-repository-languages)

## 📄 License

This configuration is provided as-is and can be freely used and modified for any project.

---

**Note**: Changes to `.gitattributes` may take some time to reflect in GitHub's language statistics. The repository may need to be re-analyzed by GitHub's Linguist engine.