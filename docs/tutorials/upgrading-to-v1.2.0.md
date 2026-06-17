# Tutorial: Upgrading to v1.2.0 (AAP 2.6)

This tutorial guides you through upgrading from v1.1.0 (AAP 2.5) to v1.2.0 (AAP 2.6).

**Time Required:** 30-45 minutes  
**Difficulty:** Intermediate  
**Prerequisites:**
- Existing v1.1.0 execution environment
- AAP platform already upgraded to 2.6
- ansible-builder and podman installed

## What You'll Learn

- How to verify AAP version compatibility
- How to rebuild execution environments with AAP 2.6 base
- How to test new v1.2.0 features (oc-mirror, PIP_INDEX_URL)
- How to update AAP configuration with new images

## Step 1: Verify AAP Platform Version

Before upgrading your execution environment, confirm your AAP platform is on version 2.6.

**Via AAP Web UI:**
1. Log into AAP Web UI
2. Navigate to **Administration** → **Execution Environments**
3. Check **Control Plane Execution Environment** image
4. Look for `ansible-automation-platform-26` in the image name

**Expected output:**
```
registry.redhat.io/ansible-automation-platform-26/ee-supported-rhel9:latest
```

**If you see `platform-25`:** Stop here. Upgrade AAP platform to 2.6 first.

## Step 2: Pull Latest Code

Get the v1.2.0 release:

```bash
cd /path/to/ocp4-aap-execution-environment
git fetch --tags
git checkout v1.2.0
```

**Verify you're on v1.2.0:**
```bash
git describe --tags
# Output: v1.2.0
```

## Step 3: Verify AAP 2.6 Base Image

Check that execution-environment.yml uses AAP 2.6:

```bash
grep "base_image" execution-environment.yml
```

**Expected output:**
```yaml
base_image:
  name: 'registry.redhat.io/ansible-automation-platform-26/ee-minimal-rhel9:latest'
```

✅ **Confirmed:** AAP 2.6 base is configured in v1.2.0.

## Step 4: Review What's New

**New features in v1.2.0:**
- AAP 2.6 base image (replaces AAP 2.5)
- oc-mirror binary for disconnected environments
- PIP_INDEX_URL custom Python index support
- Vulnerability scanning (Quay.io + Trivy)
- Image signing with cosign
- Updated dependencies (pip >=26.1.2, setuptools >=82.0.1)

**Breaking changes:**
- None! v1.2.0 is backward-compatible with v1.1.0 playbooks and collections.

**Known issues:**
- None identified. All 8 collections tested and working.

## Step 5: Set Up Build Environment

Ensure your build environment is ready:

```bash
make setup
```

**Expected output:**
```
✓ Python 3.11 found
✓ podman: podman version X.Y.Z
✓ ansible-builder: X.Y.Z
✓ ansible-navigator: X.Y.Z
✓ All required tools are installed
```

**If errors occur:** Follow the on-screen instructions to install missing tools.

## Step 6: Build v1.2.0 Execution Environment

Build your new execution environment with AAP 2.6:

```bash
export ANSIBLE_HUB_TOKEN="your-automation-hub-token"
make build
```

**Build time:** ~5-10 minutes (depending on network speed).

**What happens:**
1. Pulls AAP 2.6 base image from registry.redhat.io
2. Installs 8 Ansible collections (kubernetes.core, ansible.controller, etc.)
3. Installs Python dependencies (pip >=26.1.2, setuptools >=82.0.1)
4. Copies oc, kubectl, oc-mirror binaries
5. Runs validation steps

**Expected final output:**
```
Complete! The build context can be found at: context
```

## Step 7: Test the New Image

Run the comprehensive test suite:

```bash
make test
```

**What's tested:**
- 36 Ansible tasks across 8 collections
- kubernetes.core with oc/kubectl binaries
- ansible.hub and ansible.controller modules
- AWS, Azure, community.general collections

**Expected output:**
```
PLAY RECAP *****
localhost: ok=36 changed=0 unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

**If any tests fail:** See [Troubleshoot EE Builds](../how-to/troubleshoot-ee-builds.md).

## Step 8: Test New v1.2.0 Features

### Test oc-mirror Binary

```bash
# Verify oc-mirror is available
podman run --rm ocp4-aap-execution-environment:latest which oc-mirror

# Expected output: /usr/local/bin/oc-mirror

# Check version
podman run --rm ocp4-aap-execution-environment:latest oc-mirror version
```

**See full guide:** [Using oc-mirror](../how-to/use-oc-mirror.md)

### Test Custom Python Index (PIP_INDEX_URL)

Build with custom Python mirror:

```bash
ansible-builder build \
  --build-arg PIP_INDEX_URL=https://your-mirror.com/simple \
  -t custom-ee:latest
```

**See full guide:** [Custom Python Indexes](../how-to/custom-python-index.md)

### Test Vulnerability Scanning

```bash
# Local scan with Trivy
make scan-local

# Publish and scan with Quay.io
make publish
make scan
```

**See full guide:** [Makefile Reference](../reference/make-targets.md#security-scanning)

## Step 9: Publish to Registry

Tag and push to Quay.io:

```bash
make publish
```

**What happens:**
1. Tags image as `:latest` and `:v1.2.0`
2. Pushes both tags to quay.io
3. Quay.io automatically scans for vulnerabilities

**Verify in Quay.io:**
1. Visit https://quay.io/repository/your-org/ocp4-aap-execution-environment
2. Check **Tags** tab - should see `v1.2.0` and `latest`
3. Check **Security Scan** tab - review vulnerabilities

## Step 10: (Optional) Sign Images

For supply chain security:

```bash
# Generate signing key (first time only)
make generate-signing-key

# Sign published images
export COSIGN_PASSWORD="your-passphrase"
make sign

# Verify signatures
make verify-signature
```

**See full guide:** [Sign and Verify Images](../how-to/sign-and-verify-images.md)

## Step 11: Update AAP Configuration

Point AAP to your new v1.2.0 image:

**Via AAP Web UI:**
1. Log into AAP
2. Navigate to **Administration** → **Execution Environments**
3. Click on your custom execution environment
4. Update **Image** field to:
   ```
   quay.io/your-org/ocp4-aap-execution-environment:v1.2.0
   ```
5. Save

**Or use `:latest` tag:**
```
quay.io/your-org/ocp4-aap-execution-environment:latest
```

This auto-updates when you push new `:latest` tags.

## Step 12: Run Test Job in AAP

Create a test job template:

1. **Create Test Playbook:**
```yaml
---
- name: Test v1.2.0 Execution Environment
  hosts: localhost
  gather_facts: false
  tasks:
    - name: Check Ansible version
      ansible.builtin.debug:
        msg: "Ansible: {{ ansible_version.full }}"

    - name: Verify kubernetes.core collection
      ansible.builtin.command: ansible-doc kubernetes.core.k8s
      register: k8s_doc

    - name: Verify oc binary
      ansible.builtin.command: oc version --client
      register: oc_version

    - name: Verify oc-mirror binary
      ansible.builtin.command: which oc-mirror
      register: oc_mirror_path

    - name: Display results
      ansible.builtin.debug:
        msg:
          - "✓ kubernetes.core: Available"
          - "✓ oc version: {{ oc_version.stdout_lines[0] }}"
          - "✓ oc-mirror: {{ oc_mirror_path.stdout }}"
```

2. **Run in AAP:**
   - Create new Job Template
   - Select your v1.2.0 execution environment
   - Run job

**Expected result:** All tasks pass, confirming v1.2.0 is working.

## Step 13: Rollback (If Needed)

If issues occur, revert to v1.1.0:

```bash
# Update AAP EE configuration
Image: quay.io/your-org/ocp4-aap-execution-environment:v1.1.0
```

**Note:** v1.1.0 only works with AAP 2.5 platforms.

## Troubleshooting

### Issue: "Image pull failed - unauthorized"

**Solution:**
```bash
# Verify Quay credentials
podman login quay.io

# Verify image exists
podman pull quay.io/your-org/ocp4-aap-execution-environment:v1.2.0
```

### Issue: "Collection not found"

**Solution:**
Verify ANSIBLE_HUB_TOKEN is set correctly:
```bash
echo $ANSIBLE_HUB_TOKEN
# Should print your token

# Rebuild with token
make clean
make build
```

### Issue: "oc-mirror not found"

**Solution:**
Verify build completed successfully:
```bash
podman run --rm ocp4-aap-execution-environment:latest ls -l /usr/local/bin/oc-mirror

# If missing, rebuild:
make clean
make build
```

## Next Steps

Now that you're on v1.2.0, explore new features:

- **Disconnected Environments:** [Using oc-mirror](../how-to/use-oc-mirror.md)
- **Custom Python Mirrors:** [Custom Python Indexes](../how-to/custom-python-index.md)
- **Security Hardening:** [Sign and Verify Images](../how-to/sign-and-verify-images.md)
- **Full Documentation:** [Documentation Home](../index.md)

## Summary

✅ You've successfully upgraded to v1.2.0 with AAP 2.6 support!

**What you accomplished:**
- Verified AAP 2.6 platform compatibility
- Built execution environment with AAP 2.6 base
- Tested all collections and new binaries (oc-mirror)
- Published and scanned images
- Updated AAP configuration
- Verified functionality with test job

**Key changes in v1.2.0:**
- AAP 2.5 → AAP 2.6 base image
- Added oc-mirror for disconnected environments
- Added PIP_INDEX_URL support
- Enhanced security (scanning + signing)
- Updated dependencies

For questions or issues, see [Troubleshoot EE Builds](../how-to/troubleshoot-ee-builds.md).
