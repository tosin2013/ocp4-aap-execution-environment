# AAP Execution Environment Version Compatibility

## Version Alignment Requirement

**Critical:** Custom execution environments MUST use base images that match the deployed AAP platform version.

## Version History

### v26 (Current) - June 9, 2026
- **Base Image:** `registry.redhat.io/ansible-automation-platform-26/ee-minimal-rhel9:latest`
- **AAP Platform:** 2.6 (ansible-automation-platform-26)
- **Image Tag:** `quay.io/takinosh/ocp4-aap-execution-environment:v26`
- **Status:** Active

### v25 (Deprecated) - June 9, 2026
- **Base Image:** `registry.redhat.io/ansible-automation-platform-25/ee-minimal-rhel9:latest`
- **AAP Platform:** 2.5 (ansible-automation-platform-25)
- **Image Tag:** `quay.io/takinosh/ocp4-aap-execution-environment:latest` (old)
- **Status:** Version mismatch with AAP 2.6 - DEPRECATED

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

When upgrading AAP platform:

1. **Before AAP Upgrade:**
   - Note current AAP version (e.g., 2.5)
   - Document custom EE base image version

2. **After AAP Upgrade:**
   - Update `execution-environment.yml` with new base image
   - Rebuild custom EE with matching version
   - Push new image to Quay
   - Update AAP EE configuration (or wait for auto-pull)
   - Test job templates with new EE

3. **Verification:**
   - Run test job template
   - Verify collections are available
   - Verify oc/kubectl binaries work
   - Check AAP job logs for EE pull success

## References

- **AAP Documentation:** https://access.redhat.com/documentation/en-us/red_hat_ansible_automation_platform/2.6
- **Execution Environments Guide:** https://docs.ansible.com/automation-controller/latest/html/userguide/execution_environments.html
- **Base Images Registry:** registry.redhat.io/ansible-automation-platform-{VERSION}/
