# Contributing to AndroidLab

First off, thank you for considering contributing to AndroidLab! 🎉

## How Can I Contribute?

### 🐛 Reporting Bugs

- Use the [Bug Report template](../../issues/new?template=bug_report.md)
- Include your phone model, Android version, and Termux version
- Provide exact error messages and logs
- Describe what you expected vs. what actually happened

### 💡 Suggesting Features

- Use the [Feature Request template](../../issues/new?template=feature_request.md)
- Explain the use case and why it would benefit others
- Check existing issues first to avoid duplicates

### 📝 Improving Documentation

- Fix typos, clarify instructions, add missing steps
- Add support for specific phone models or Android versions
- Translate documentation to other languages

### 🔧 Contributing Code

1. **Fork** the repository
2. **Clone** your fork:
   ```bash
   git clone https://github.com/yourusername/androidlab.git
   cd androidlab
   ```
3. **Create a branch** for your feature:
   ```bash
   git checkout -b feature/my-improvement
   ```
4. **Make your changes** and test them on an actual Android device if possible
5. **Commit** with a clear message:
   ```bash
   git commit -m "Add: description of what you added"
   ```
6. **Push** to your fork:
   ```bash
   git push origin feature/my-improvement
   ```
7. **Open a Pull Request** against the `main` branch

## Commit Message Convention

Use prefixes to categorize your changes:

| Prefix | Use For |
|--------|---------|
| `Add:` | New features, scripts, or services |
| `Fix:` | Bug fixes |
| `Docs:` | Documentation changes |
| `Improve:` | Performance or code improvements |
| `Security:` | Security-related changes |
| `Refactor:` | Code restructuring |

**Examples:**
```
Add: Redis installation guide in Phase 6
Fix: MariaDB startup script on Samsung devices
Docs: clarify SSH key setup for Windows users
Improve: reduce memory usage of watchdog script
```

## What We're Looking For

- ✅ Support for additional services (Redis, Gitea, Nextcloud, WireGuard, Pi-hole, etc.)
- ✅ Device-specific fixes (Samsung, Xiaomi, Huawei, Pixel, etc.)
- ✅ Additional monitoring and alerting scripts
- ✅ Security improvements and hardening guides
- ✅ Performance optimization tips
- ✅ One-command setup automation
- ✅ Backup and disaster recovery improvements
- ✅ CI/CD pipeline for testing scripts

## Code Style Guidelines

### Shell Scripts (`.sh`)
- Use `#!/data/data/com.termux/files/usr/bin/bash` shebang for Termux scripts
- Add comments explaining non-obvious commands
- Use `set -euo pipefail` for production scripts
- Quote all variables: `"$VARIABLE"` not `$VARIABLE`
- Use `shellcheck` if available

### Python Scripts (`.py`)
- Follow PEP 8 style guidelines
- Add docstrings to functions and modules
- Use type hints where practical
- Keep imports organized (stdlib, third-party, local)

### Configuration Files
- Add comment headers explaining the purpose
- Document every non-default setting
- Use example values, never hardcode real credentials

## Testing

- Test your changes on an actual Android device running Termux
- If device testing isn't possible, clearly state this in your PR
- Include the output of relevant commands showing your changes work
- Test on both ARM and ARM64 if possible

## Code of Conduct

Please read and follow our [Code of Conduct](CODE_OF_CONDUCT.md).

## Questions?

Open a [Discussion](../../discussions) or create an issue tagged with `question`.

---

Thank you for helping make AndroidLab better! 🚀
