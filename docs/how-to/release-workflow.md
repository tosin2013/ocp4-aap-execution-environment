# Release Workflow: Dependabot to Production

**Status:** Active  
**Last Updated:** 2026-06-17  
**Applies to:** v1.2.0 and later

## Overview

This guide documents the complete workflow for managing dependency updates and creating releases, from Dependabot PR creation through to production deployment on Quay.io.

## Table of Contents

- [Understanding the Pipeline](#understanding-the-pipeline)
- [Reviewing Dependabot PRs](#reviewing-dependabot-prs)
- [Merging Dependabot PRs](#merging-dependabot-prs)
- [Creating Versioned Releases](#creating-versioned-releases)
- [Verification Checklist](#verification-checklist)
- [Troubleshooting](#troubleshooting)

---

## Understanding the Pipeline

### Automatic Builds (`:latest` tag)

```
Dependabot PR merged → GitHub Actions build → Quay.io :latest tag
```

**Triggers:** Any push to `main` branch  
**Tag produced:** `quay.io/takinosh/ocp4-aap-execution-environment:latest`  
**Steps run:** Build, Test, Verify, Trivy Scan, Publish  
**Steps skipped:** Quay.io scan, cosign signing (release-only)

### Release Builds (versioned tags)

```
Git tag pushed → GitHub Actions build → Quay.io :vX.Y.Z + :latest tags
```

**Triggers:** Any git tag matching `v*` pattern  
**Tags produced:**
- `quay.io/takinosh/ocp4-aap-execution-environment:vX.Y.Z`
- `quay.io/takinosh/ocp4-aap-execution-environment:latest` (updated)

**All steps run:** Build, Test, Verify, Trivy Scan, Publish, Quay.io Scan, cosign Signing

---

## Reviewing Dependabot PRs

### List Open Dependabot PRs

```bash
gh pr list --author "app/dependabot"
```

**Example output:**
```
15: docs(deps-dev): update ansible-core requirement from <2.18.0,>=2.15.13 to >=2.21.0,<2.22.0
14: docs(deps-dev): update ansible-builder requirement from <4.0.0,>=3.0.0 to >=3.1.1,<4.0.0
13: docs(deps): update mkdocs requirement from >=1.5.0 to >=1.6.1
12: ci(deps): bump sigstore/cosign-installer from 3.7.0 to 4.1.2
11: ci(deps): bump actions/configure-pages from 5 to 6
```

### Review Individual PR

```bash
gh pr view 15
```

**What to check:**
- ✅ Dependency update is legitimate (not malicious)
- ✅ Version bump makes sense (check changelog/release notes)
- ✅ CI checks are passing (all green)
- ✅ No breaking changes noted in PR description

### Check CI Status

```bash
gh pr checks 15
```

**Expected:**
```
✓ Build and Publish EE (Podman)
✓ Documentation Build
```

---

## Merging Dependabot PRs

### Strategy 1: Batch Merge (Recommended)

**When to use:** Multiple PRs accumulated (5-10 PRs)

```bash
# Review all PRs first
gh pr list --author "app/dependabot"

# Batch merge
gh pr merge 11 --squash --delete-branch
gh pr merge 12 --squash --delete-branch
gh pr merge 13 --squash --delete-branch
gh pr merge 14 --squash --delete-branch
gh pr merge 15 --squash --delete-branch
```

**Benefits:**
- One `:latest` image with all updates
- Single test cycle
- Cleaner git history

### Strategy 2: Individual Merge

**When to use:** Critical security update, urgent fix

```bash
gh pr merge 12 --squash --delete-branch
```

### Post-Merge: Verify `:latest` Build

```bash
# Wait for build to complete
gh run list --workflow="build-and-push.yml" --branch main --limit 1

# Monitor if needed
gh run watch <run-id>
```

**Expected:** Build completes in 8-10 minutes with all checks passing

---

## Creating Versioned Releases

### Step 1: Determine Version Number

Follow [Semantic Versioning](https://semver.org/):

**PATCH (v1.2.X):** Bug fixes, dependency updates, documentation
- ✅ Dependabot dependency updates
- ✅ Documentation improvements
- ✅ Bug fixes with no new features
- **Example:** v1.2.0 → v1.2.1

**MINOR (v1.X.0):** New features, backward-compatible changes
- ✅ New collections added
- ✅ New binaries included (e.g., oc-mirror)
- ✅ New environment variables supported
- **Example:** v1.2.1 → v1.3.0

**MAJOR (vX.0.0):** Breaking changes
- ✅ Dropping support for AAP version
- ✅ Removing collections
- ✅ Changing build process fundamentally
- **Example:** v1.3.0 → v2.0.0

### Step 2: Update CHANGELOG.md

```bash
# Edit CHANGELOG.md
vim CHANGELOG.md
```

**Add new version section:**
```markdown
## [1.2.1] - 2026-06-XX

### Changed
- ansible-core updated from 2.18.0 to 2.21.0
- ansible-builder updated from 3.0.0 to 3.1.1
- mkdocs updated from 1.5.0 to 1.6.1
- sigstore/cosign-installer updated from 3.7.0 to 4.1.2
- actions/configure-pages updated from 5 to 6

### Security
- All dependencies scanned with Trivy and Quay.io
- No HIGH or CRITICAL vulnerabilities found
```

**Commit changelog:**
```bash
git add CHANGELOG.md
git commit -m "docs: finalize CHANGELOG for v1.2.1"
git push origin main
```

### Step 3: Pull Latest Changes

```bash
git pull origin main
```

**Verify you're on latest commit:**
```bash
git log --oneline -5
```

### Step 4: Create Annotated Tag

```bash
git tag -a v1.2.1 -m "Release v1.2.1: Dependency updates

Dependencies Updated:
- ansible-core 2.21.0 (from 2.18.0)
- ansible-builder 3.1.1 (from 3.0.0)
- mkdocs 1.6.1 (from 1.5.0)
- cosign-installer 4.1.2 (from 3.7.0)
- configure-pages v6 (from v5)

Security:
- All dependencies scanned for vulnerabilities
- No HIGH or CRITICAL issues found

Tested with AAP 2.6 execution environments.
Ready for production use."
```

**Best practices:**
- ✅ Use annotated tags (`-a`) not lightweight tags
- ✅ Include summary of changes in tag message
- ✅ Reference security status
- ✅ Keep message concise but informative

### Step 5: Push Tag to Trigger Release

```bash
git push origin v1.2.1
```

**This triggers:**
1. GitHub Actions workflow (refs/tags/v1.2.1)
2. Full build pipeline including security scans
3. Publish to Quay.io with both `:v1.2.1` and `:latest` tags
4. Image signing with cosign (if configured)

### Step 6: Monitor Release Build

```bash
# Find the build triggered by tag
gh run list --workflow="build-and-push.yml" --limit 3

# Monitor it
gh run watch <run-id>
```

**Expected timeline:**
- Build: ~7-8 minutes
- Test: ~30 seconds
- Verify: ~10 seconds
- Security Scan (Trivy): ~30 seconds
- Publish: ~1-2 minutes
- Security Scan (Quay.io): ~30 seconds (async, happens on Quay's side)
- Sign Images: ~10 seconds

**Total:** ~9-10 minutes

### Step 7: Verify Published Images

```bash
# Check tags on Quay.io
curl -s "https://quay.io/api/v1/repository/takinosh/ocp4-aap-execution-environment/tag/?limit=5&onlyActiveTags=true" \
  | jq -r '.tags[] | "\(.name) - \(.last_modified)"'
```

**Expected output:**
```
latest - Wed, 17 Jun 2026 17:49:55 -0000
v1.2.1 - Wed, 17 Jun 2026 17:49:51 -0000
v1.2.0 - Wed, 17 Jun 2026 17:49:51 -0000
```

**Verify image works:**
```bash
# Pull and test
podman pull quay.io/takinosh/ocp4-aap-execution-environment:v1.2.1

# Quick smoke test
podman run --rm quay.io/takinosh/ocp4-aap-execution-environment:v1.2.1 \
  ansible-navigator --version
```

### Step 8: Create GitHub Release

```bash
gh release create v1.2.1 \
  --title "v1.2.1 - Dependency Updates" \
  --generate-notes
```

**Or with custom notes:**
```bash
gh release create v1.2.1 \
  --title "v1.2.1 - Dependency Updates" \
  --notes "## Quick Start

\`\`\`bash
podman pull quay.io/takinosh/ocp4-aap-execution-environment:v1.2.1
\`\`\`

## Changes

See [CHANGELOG.md](https://github.com/tosin2013/ocp4-aap-execution-environment/blob/v1.2.1/CHANGELOG.md) for full details.

## Dependencies Updated

- ansible-core 2.21.0
- ansible-builder 3.1.1
- mkdocs 1.6.1
- cosign-installer 4.1.2
- configure-pages v6"
```

---

## Verification Checklist

Before announcing a release, verify:

### Build Verification
- [ ] GitHub Actions workflow completed successfully
- [ ] All tests passed (36 Ansible tasks)
- [ ] AAP 2.6 base image verified
- [ ] oc-mirror binary verified
- [ ] Trivy scan completed (no blocking vulnerabilities)
- [ ] Quay.io scan triggered
- [ ] Images signed with cosign (if configured)

### Artifact Verification
- [ ] `:vX.Y.Z` tag exists on Quay.io
- [ ] `:latest` tag updated on Quay.io
- [ ] Image pull works: `podman pull quay.io/takinosh/ocp4-aap-execution-environment:vX.Y.Z`
- [ ] Image runs: `podman run --rm <image> ansible-navigator --version`

### Documentation Verification
- [ ] CHANGELOG.md updated with version
- [ ] GitHub Release created
- [ ] Release notes include image pull command
- [ ] Links to documentation work

---

## Troubleshooting

### Build Fails After Tag Push

**Check build logs:**
```bash
gh run view <run-id> --log-failed
```

**Common issues:**
- Dependabot updated package to incompatible version
- New dependency conflicts with existing ones
- Security scan finds new vulnerability

**Resolution:**
```bash
# Delete failed tag
git tag -d v1.2.1
git push origin :refs/tags/v1.2.1

# Fix issue in main branch
# Then recreate tag
```

### Wrong Tag Pushed

**Delete remote tag:**
```bash
git push origin :refs/tags/v1.2.1
```

**Delete local tag:**
```bash
git tag -d v1.2.1
```

**Recreate correctly:**
```bash
git tag -a v1.2.1 -m "Correct message"
git push origin v1.2.1
```

### Image Not on Quay.io

**Check publish step succeeded:**
```bash
gh run view <run-id> --log | grep -A 20 "Publish"
```

**Common causes:**
- QUAY_USERNAME or QUAY_PASSWORD secret incorrect
- Repository doesn't exist
- Network timeout during push

### `:latest` Not Updated

**Expected behavior:**
- Tagged builds update BOTH `:vX.Y.Z` AND `:latest`
- Check Makefile `publish` target includes both pushes

**Verify:**
```bash
grep -A 10 "^publish:" Makefile
```

Should show:
```makefile
$(CONTAINER_ENGINE) push $(TARGET_HUB)/$(TARGET_USERNAME)/$(TARGET_NAME):$(TARGET_TAG)
$(CONTAINER_ENGINE) push $(TARGET_HUB)/$(TARGET_USERNAME)/$(TARGET_NAME):latest
```

---

## Release Cadence Recommendations

### Suggested Schedule

**PATCH releases (dependency updates):**
- **Monthly** - After batch-merging Dependabot PRs
- Good for: Routine dependency updates, documentation fixes

**MINOR releases (new features):**
- **Quarterly** - When new features are ready
- Good for: New collections, new binaries, new capabilities

**MAJOR releases (breaking changes):**
- **Yearly** - When dropping old platform support
- Good for: AAP version upgrades that drop old support

### Example Calendar

```
January:   v1.2.1 (PATCH - Dependabot)
February:  v1.2.2 (PATCH - Dependabot)
March:     v1.3.0 (MINOR - New features)
April:     v1.3.1 (PATCH - Dependabot)
May:       v1.3.2 (PATCH - Dependabot)
June:      v1.3.3 (PATCH - Dependabot + v1.2.0 actual release)
July:      v1.4.0 (MINOR - New features)
...
```

---

## Automation Considerations

### Why Manual Releases?

**Benefits of current approach:**
1. **Batch efficiency** - Merge 5 PRs, create 1 release (not 5)
2. **Semantic control** - You decide PATCH vs MINOR vs MAJOR
3. **Quality gates** - Time to test `:latest` before release
4. **Better notes** - Manual releases have better changelog/notes
5. **Flexibility** - Release when ready, not forced by automation

### Future Automation Options

If needed, consider:
- **Scheduled releases:** GitHub Actions cron job to create monthly releases
- **Auto-PATCH:** Dependabot merges trigger PATCH version bump
- **Release bot:** Custom bot that follows semantic versioning rules

**Current recommendation:** Keep manual process until release cadence is well-established

---

## Related Documentation

- [Dependabot and Release Management](./dependabot-releases.md) - PR review checklist
- [CI/CD Pipeline](./ci-cd.md) - GitHub Actions workflow details
- [Security Scanning](../adrs/0009-security-scanning-strategy.md) - Vulnerability scanning approach
- [Image Signing](./sign-and-verify-images.md) - cosign signing and verification

---

## Real Example: v1.2.0 Release

**Timeline (2026-06-17):**

1. **09:00 - Batch merge 5 Dependabot PRs**
   ```bash
   gh pr merge 11 12 13 14 15 --squash --delete-branch
   ```

2. **09:10 - Verify `:latest` build**
   - Build completed successfully
   - All tests passed
   - Published to Quay.io as `:latest`

3. **09:15 - Update CHANGELOG.md**
   - Documented all dependency updates
   - Committed to main

4. **09:20 - Create and push tag**
   ```bash
   git pull origin main
   git tag -a v1.2.0 -m "Release v1.2.0: AAP 2.6, oc-mirror, security hardening"
   git push origin v1.2.0
   ```

5. **09:30 - Release build completed**
   - Build time: 9m38s
   - Published to Quay.io as `:v1.2.0` and `:latest`
   - All security scans passed
   - Images signed with cosign

6. **09:35 - Created GitHub Release**
   ```bash
   gh release create v1.2.0 --notes-file release-notes.md
   ```

7. **09:40 - Verified artifacts**
   ```bash
   podman pull quay.io/takinosh/ocp4-aap-execution-environment:v1.2.0
   # Success!
   ```

**Total time:** ~40 minutes (mostly automated build time)

---

## Summary

1. **Dependabot creates PRs** → Review weekly/monthly
2. **Batch merge PRs** → Builds `:latest` automatically
3. **Create git tag** → Triggers release build
4. **Release build publishes** → Both `:vX.Y.Z` and `:latest` tags
5. **Create GitHub Release** → Document changes

**Key principle:** `:latest` is the test bed, versioned tags are production releases.
