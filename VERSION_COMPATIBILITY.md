# AAP Execution Environment Version Compatibility

## Version Alignment Requirement

**Critical:** Custom execution environments MUST use base images that match the deployed AAP platform version.

## Version History

### v1.2.0 (Current) - June 17, 2026
- **Base Image:** `registry.redhat.io/ansible-automation-platform-26/ee-minimal-rhel9:latest`
- **AAP Platform:** 2.6 (ansible-automation-platform-26)
- **Release Tag:** `v1.2.0`
- **Image Tags:** `quay.io/takinosh/ocp4-aap-execution-environment:v1.2.0`, `:latest`
- **OpenShift CLI:** oc/kubectl v4.21.9
- **New Features:** oc-mirror binary, PIP_INDEX_URL support, updated dependencies
- **Status:** Active (production-ready)

### v26 (Superseded by v1.2.0) - June 9, 2026
- **Base Image:** `registry.redhat.io/ansible-automation-platform-26/ee-minimal-rhel9:latest`
- **AAP Platform:** 2.6 (ansible-automation-platform-26)
- **Image Tag:** `quay.io/takinosh/ocp4-aap-execution-environment:v26`
- **Status:** Superseded by v1.2.0 semantic versioning release

### v1.1.0 - April 21, 2026
- **Base Image:** `registry.redhat.io/ansible-automation-platform-25/ee-minimal-rhel9:latest`
- **AAP Platform:** 2.5 (ansible-automation-platform-25)
- **Release Tag:** `v1.1.0`
- **OpenShift CLI:** oc/kubectl v4.21.9
- **Features:** ADR framework (8 ADRs), OpenShift 4.21 support, Dependabot
- **Status:** Compatible with AAP 2.5 only - upgrade to v1.2.0 for AAP 2.6

### v25 (Legacy) - June 9, 2026
- **Base Image:** `registry.redhat.io/ansible-automation-platform-25/ee-minimal-rhel9:latest`
- **AAP Platform:** 2.5 (ansible-automation-platform-25)
- **Image Tag:** `quay.io/takinosh/ocp4-aap-execution-environment:latest` (old)
- **Status:** DEPRECATED - Incompatible with AAP 2.6 platforms

## Error Symptoms

### Version Mismatch Error
```
Error: unable to copy from source docker://registry.redhat.io/ansible-automation-platform-26/ee-supported-rhel9:latest
initializing source docker://registry.redhat.io/ansible-automation-platform-26/ee-supported-rhel9:latest
unable to retrieve auth token: invalid username/password: unauthorized
```

**Root Cause:** AAP 2.6 trying to pull AAP 26 images, but custom EE built with AAP 25 base.

**Resolution:** Rebuild custom EE with matching AAP 26 base image.

## Determining AAP Platform Version

### Via Web UI
1. Log into AAP Web UI
2. Navigate to: **Administration** → **Execution Environments**
3. Check **Control Plane Execution Environment** image:
   - `ansible-automation-platform-26` = AAP 2.6
   - `ansible-automation-platform-25` = AAP 2.5

### Via API
```bash
curl -sk -u admin:password https://aap.example.com/api/controller/v2/execution_environments/3/ | \
  jq -r '.image'
```

### Via AAP About Page
1. Log into AAP Web UI
2. Click user icon (top right)
3. Click **About**
4. Check version number

## Build Commands

### AAP 2.6 (Current)
```bash
# Update execution-environment.yml
sed -i 's/ansible-automation-platform-25/ansible-automation-platform-26/' execution-environment.yml

# Build
sudo su -c "
ansible-builder build -t quay.io/takinosh/ocp4-aap-execution-environment:v26 \
  --build-arg REGISTRY_USERNAME='SERVICE_ACCOUNT_ID' \
  --build-arg REGISTRY_PASSWORD='TOKEN' \
  --container-runtime=podman \
  -v 1
"

# Tag as latest
sudo podman tag quay.io/takinosh/ocp4-aap-execution-environment:v26 \
                quay.io/takinosh/ocp4-aap-execution-environment:latest

# Push both tags
sudo podman push quay.io/takinosh/ocp4-aap-execution-environment:v26
sudo podman push quay.io/takinosh/ocp4-aap-execution-environment:latest
```

### AAP 2.5 (Legacy)
```bash
# execution-environment.yml
images:
  base_image:
    name: 'registry.redhat.io/ansible-automation-platform-25/ee-minimal-rhel9:latest'
```

## Upgrade Path

### Upgrading from v1.1.0 (AAP 2.5) to v1.2.0 (AAP 2.6)

**Prerequisites:**
- AAP platform already upgraded to 2.6
- Access to build server with ansible-builder
- Red Hat Automation Hub token configured

**Steps:**

1. **Pull Latest Code:**
   ```bash
   git clone https://github.com/tosin2013/ocp4-aap-execution-environment.git
   cd ocp4-aap-execution-environment
   git checkout v1.2.0
   ```

2. **Verify Base Image (Already AAP 2.6):**
   ```bash
   grep "base_image" execution-environment.yml
   # Should show: ansible-automation-platform-26/ee-minimal-rhel9:latest
   ```

3. **Build New Execution Environment:**
   ```bash
   make setup  # Create venv and verify tools
   make build  # Build with AAP 2.6 base
   ```

4. **Test Locally:**
   ```bash
   make test  # Run 36-task functional playbook
   ```

5. **Publish to Registry:**
   ```bash
   make publish  # Push to Quay with v1.2.0 tag
   ```

6. **Update AAP Configuration:**
   - Log into AAP Web UI
   - Navigate to Administration → Execution Environments
   - Update image reference to `quay.io/takinosh/ocp4-aap-execution-environment:v1.2.0`
   - Or rely on `:latest` tag auto-pull

7. **Verification:**
   - Run test job template in AAP
   - Verify all 8 collections available (ansible.controller, ansible.hub, kubernetes.core, etc.)
   - Verify oc/kubectl v4.21.9 accessible
   - Verify oc-mirror available
   - Check AAP job logs for successful EE pull

**Rollback:**
If issues occur, revert to v1.1.0:
```bash
# Update AAP EE configuration
Image: quay.io/takinosh/ocp4-aap-execution-environment:v1.1.0
```

### Upgrading AAP Platform First

When upgrading AAP platform from 2.5 to 2.6:

1. **Before AAP Upgrade:**
   - Note current EE version (v1.1.0)
   - Document any custom collections or dependencies
   - Backup AAP configuration

2. **After AAP Upgrade (2.5 → 2.6):**
   - Immediately upgrade EE to v1.2.0 (follows steps above)
   - AAP 2.6 requires AAP 26 base image - v1.1.0 will fail

3. **Verification:**
   - Run full test suite
   - Verify no collection compatibility issues
   - Check for any Ansible Core version conflicts

## References

- **AAP Documentation:** https://access.redhat.com/documentation/en-us/red_hat_ansible_automation_platform/2.6
- **Execution Environments Guide:** https://docs.ansible.com/automation-controller/latest/html/userguide/execution_environments.html
- **Base Images Registry:** registry.redhat.io/ansible-automation-platform-{VERSION}/
