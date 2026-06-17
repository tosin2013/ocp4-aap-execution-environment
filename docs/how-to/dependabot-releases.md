# Dependabot and Release Management

This guide explains how Dependabot manages dependency updates and when they trigger new releases.

## Dependabot Configuration

Dependabot is configured via `.github/dependabot.yml` to automatically create PRs for dependency updates.

### Update Schedules

| Ecosystem | Interval | Day | Time | Max PRs |
|-----------|----------|-----|------|---------|
| GitHub Actions | Weekly | Monday | 09:00 | 5 |
| Docker (base image) | Monthly | Monday | 09:00 | 3 |
| Python (files/requirements.txt) | Monthly | Monday | 09:00 | 5 |
| Python (docs) | Monthly | Monday | 09:00 | 3 |

### Grouping Strategy

**Python packages:** Minor and patch updates grouped into single PR to reduce noise
```yaml
groups:
  python-packages:
    patterns: ["*"]
    update-types: ["minor", "patch"]
```

**Base image:** Patch updates ignored (too frequent, reviewed monthly)
```yaml
ignore:
  - dependency-name: "registry.redhat.io/ansible-automation-platform-26/ee-minimal-rhel9"
    update-types: ["version-update:semver-patch"]
```

## When Dependabot Updates Trigger Releases

Not all Dependabot PRs require a new release. Use semantic versioning to determine release impact:

### PATCH Release (v1.2.x)

**Trigger PRs:**
- Python package patch updates (pip, setuptools)
- GitHub Actions patch updates
- Documentation dependency updates (mkdocs-material)

**Example:**
- PR: `build(deps): update pip requirement from >=26.1.2 to >=26.1.3`
- Impact: Low - backward-compatible bug fixes
- Action: Merge → Create v1.2.1 release
- CHANGELOG: Add to `[1.2.1]` section under `### Changed`

### MINOR Release (v1.x.0)

**Trigger PRs:**
- Python package minor updates (new features, backward-compatible)
- New AAP minor version (AAP 2.6.1 → 2.7.0)
- GitHub Actions with new features
- New Ansible collections added
- New binaries added (oc-mirror was v1.2.0)

**Example:**
- PR: `build(deps): update setuptools requirement from >=82.0.1 to >=83.0.0`
- Impact: Medium - new features, backward-compatible
- Action: Merge → Create v1.3.0 release
- CHANGELOG: Add to `[1.3.0]` section under `### Changed` or `### Added`

### MAJOR Release (vX.0.0)

**Trigger PRs:**
- AAP major version upgrade (AAP 2.x → 3.x)
- Python major version change (Python 3.11 → 3.12 required)
- Breaking changes in collections
- Removal of deprecated features

**Example:**
- PR: `build(deps): update base image to AAP 3.0`
- Impact: High - breaking changes expected
- Action: Review carefully → Extensive testing → Create v2.0.0 release
- CHANGELOG: Add to `[2.0.0]` section with `### Breaking Changes`

## Dependabot PR Review Checklist

Before merging any Dependabot PR:

### 1. Review the PR

```bash
# View PR details
gh pr view <PR_NUMBER>

# Check files changed
gh pr diff <PR_NUMBER>
```

### 2. Verify CI Passes

**Critical checks:**
- ✅ Yamllint
- ✅ Docs Build (strict mode)
- ✅ Validate GitHub Actions Workflows
- ⚠️ Build and Publish EE (expected to fail on main - requires secrets)

**Note:** Build failures on `main` branch are normal (missing `ANSIBLE_HUB_TOKEN`). The workflow will succeed when:
- Manually triggered with secrets
- Tag pushed (release workflow)

### 3. Test Locally (for significant updates)

```bash
# Checkout PR branch
gh pr checkout <PR_NUMBER>

# Build with updated dependencies
make clean
make build

# Run functional tests
make test

# Verify no regressions
make scan-local
```

### 4. Merge Strategy

**Minor updates (patch/minor):**
```bash
# Auto-merge if CI passes
gh pr merge <PR_NUMBER> --auto --squash
```

**Major updates:**
```bash
# Manual review + testing required
gh pr review <PR_NUMBER> --approve
gh pr merge <PR_NUMBER> --squash
```

## Creating Releases After Merge

### Step 1: Update CHANGELOG

Determine version bump based on ADR-0001 (Semantic Versioning):

```bash
# Edit CHANGELOG.md
vim CHANGELOG.md

# Move dependency updates from [Unreleased] to [1.2.1]
# Format:
## [1.2.1] - YYYY-MM-DD

### Changed
- pip updated from >=26.1.2 to >=26.1.3 ([PR #XX])
- setuptools updated from >=82.0.1 to >=82.0.2 ([PR #YY])
```

### Step 2: Commit CHANGELOG

```bash
git add CHANGELOG.md
git commit -m "docs: prepare v1.2.1 release

- Updated pip to >=26.1.3
- Updated setuptools to >=82.0.2
"
git push origin main
```

### Step 3: Create Git Tag

```bash
# Create annotated tag
git tag -a v1.2.1 -m "Release v1.2.1: Dependency updates

### Changed
- pip updated from >=26.1.2 to >=26.1.3 (PR #XX)
- setuptools updated from >=82.0.1 to >=82.0.2 (PR #YY)
"

# Push tag
git push origin v1.2.1
```

### Step 4: Create GitHub Release

**Automated (via CLI):**
```bash
gh release create v1.2.1 \
  --title "v1.2.1 - Dependency Updates" \
  --notes-file - <<'EOF'
## Changed
- `pip` updated from >=26.1.2 to >=26.1.3 ([PR #XX](https://github.com/tosin2013/ocp4-aap-execution-environment/pull/XX))
- `setuptools` updated from >=82.0.1 to >=82.0.2 ([PR #YY](https://github.com/tosin2013/ocp4-aap-execution-environment/pull/YY))

## Docker Images
- **Quay.io:** `quay.io/takinosh/ocp4-aap-execution-environment:v1.2.1`
- **Latest tag:** Also updated to v1.2.1

## Compatibility
- AAP 2.6 (Ansible Automation Platform)
- OpenShift 4.21+
- Python 3.11+ (3.10 minimum)
EOF
```

**Manual (via Web UI):**
1. Go to https://github.com/tosin2013/ocp4-aap-execution-environment/releases/new
2. Choose tag: `v1.2.1`
3. Release title: `v1.2.1 - Dependency Updates`
4. Description: Copy from CHANGELOG
5. Click "Publish release"

### Step 5: Verify Release Artifacts

After tag push, GitHub Actions automatically:
- ✅ Builds execution environment
- ✅ Runs 36-task functional test suite
- ✅ Scans for vulnerabilities (Trivy)
- ✅ Publishes to `quay.io/takinosh/ocp4-aap-execution-environment:v1.2.1`
- ✅ Publishes to `quay.io/takinosh/ocp4-aap-execution-environment:latest`
- ✅ Scans with Quay.io vulnerability scanner
- ⚠️ Signs images (if `COSIGN_PRIVATE_KEY` configured)

**Verify workflow:**
```bash
# Check release workflow status
gh run list --workflow build-and-push.yml --limit 3

# View specific run
gh run view <RUN_ID>

# Check Quay.io
open https://quay.io/repository/takinosh/ocp4-aap-execution-environment?tab=tags
```

## Dependabot Auto-Merge (Optional)

To automatically merge Dependabot PRs that pass CI:

### Option 1: GitHub UI

1. Go to Repository Settings → Code and automation → Dependabot
2. Enable "Grouped security updates"
3. Enable "Auto-merge pull requests"

### Option 2: GitHub Actions Workflow

Create `.github/workflows/dependabot-auto-merge.yml`:

```yaml
name: Dependabot Auto-Merge
on: pull_request

permissions:
  contents: write
  pull-requests: write

jobs:
  dependabot:
    runs-on: ubuntu-latest
    if: github.actor == 'dependabot[bot]'
    steps:
      - name: Dependabot metadata
        id: metadata
        uses: dependabot/fetch-metadata@v2
        with:
          github-token: "${{ secrets.GITHUB_TOKEN }}"

      - name: Enable auto-merge for patch/minor updates
        if: |
          steps.metadata.outputs.update-type == 'version-update:semver-patch' ||
          steps.metadata.outputs.update-type == 'version-update:semver-minor'
        run: gh pr merge --auto --squash "$PR_URL"
        env:
          PR_URL: ${{ github.event.pull_request.html_url }}
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

**Security Note:** Only auto-merge patch/minor updates. Major updates require manual review.

## Release Frequency Guidelines

Based on ADR-0004 (Dependency Management Strategy):

**Weekly (if needed):**
- Critical security vulnerabilities
- Breaking bugs in dependencies

**Monthly (typical):**
- Routine dependency updates
- Accumulated Dependabot PRs
- Minor feature additions

**Quarterly (major releases):**
- AAP major version upgrades
- Breaking changes
- Major architectural updates

## Monitoring Dependabot

**Check for pending PRs:**
```bash
gh pr list --author "app/dependabot"
```

**View Dependabot status:**
```bash
gh api /repos/tosin2013/ocp4-aap-execution-environment/dependabot/alerts
```

**Check security alerts:**
```bash
gh api /repos/tosin2013/ocp4-aap-execution-environment/vulnerability-alerts
```

## Related Documentation

- [ADR-0001: Semantic Versioning](../adrs/0001-adopt-semantic-versioning.md)
- [ADR-0002: Release Process](../adrs/0002-release-process.md)
- [ADR-0004: Dependency Management](../adrs/0004-dependency-management.md)
- [Release Process](release-process.md)
- [CI/CD Integration](ci-cd.md)

## References

- [Dependabot Documentation](https://docs.github.com/en/code-security/dependabot)
- [Keep a Changelog](https://keepachangelog.com/)
- [Semantic Versioning](https://semver.org/)
