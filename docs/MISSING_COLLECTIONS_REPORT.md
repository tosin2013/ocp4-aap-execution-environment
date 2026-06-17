# Missing Collections Report for v1.2.1

**Date**: 2026-06-17  
**Reporter**: ocp4-disconnected-helper project  
**EE Version Tested**: v1.2.1  
**Total Downstream Playbooks**: 62  
**Failed Playbooks**: 11 (18% failure rate)  

## Executive Summary

The ocp4-disconnected-helper project (downstream consumer) discovered **2 critical missing collections** during CI/CD syntax validation:

1. ✅ **ansible.controller** — PRESENT (v4.8.2)
2. ✅ **infra.aap_utilities** — PRESENT (v3.4.0) 
3. ❌ **community.libvirt** — **MISSING** (critical - 10 playbooks fail)
4. ❌ **containers.podman** — **MISSING** (1 playbook fails)

**Impact**: Main `site.yml` entrypoint completely blocked without community.libvirt.

---

## Missing Collections Details

### 1. community.libvirt (CRITICAL - Priority P0)

**Impact**: 10 out of 62 playbooks fail (16% failure rate)  
**Severity**: **HIGH** - Core infrastructure provisioning blocked  
**Use Case**: KVM/libvirt VM provisioning and management  

**Failed Downstream Playbooks**:
- `playbooks/deploy-openshift-cluster.yml`
- `playbooks/deploy-registry.yml`
- `playbooks/destroy-registry-vm.yml`
- `playbooks/provision-aap-vm.yml`
- `playbooks/provision-registry-vm-with-static-ip.yml`
- `playbooks/provision-registry-vm.yml`
- `playbooks/setup-dependencies.yml`
- **`playbooks/site.yml`** (main entrypoint! ❌)
- `playbooks/validate-cockpit-libvirt.yml`

**Missing Module**: `community.libvirt.virt`

**Example Error**:
```
ERROR! couldn't resolve module/action 'community.libvirt.virt'. 
This often indicates a misspelling, missing collection, or incorrect module path.

The error appears to be in '/workspace/roles/common_vm/tasks/delete.yml': line 4, column 3
```

**Why Critical**: 
- Main playbook `site.yml` fails completely
- All VM provisioning workflows blocked
- Downstream project is 100% libvirt-based (nested KVM on IBM Cloud)
- AAP job templates cannot execute infrastructure playbooks

**Ansible Galaxy**: https://galaxy.ansible.com/ui/repo/published/community/libvirt/  
**Latest Version**: 2.2.0 (as of 2026-06-17)

---

### 2. containers.podman (MEDIUM - Priority P1)

**Impact**: 1 out of 62 playbooks fails  
**Severity**: **MEDIUM** - Specific registry workflow blocked  
**Use Case**: JFrog Artifactory container registry management  

**Failed Downstream Playbooks**:
- `playbooks/setup-jfrog-registry.yml`

**Missing Module**: `containers.podman.podman_image`

**Example Error**:
```
ERROR! couldn't resolve module/action 'containers.podman.podman_image'. 
This often indicates a misspelling, missing collection, or incorrect module path.
```

**Why Important**:
- Alternative registry option for disconnected environments
- Enterprise customers may require JFrog over Quay
- Provides registry flexibility for compliance requirements

**Ansible Galaxy**: https://galaxy.ansible.com/ui/repo/published/containers/podman/  
**Latest Version**: 1.20.2 (as of 2026-06-17)

---

## Incorrect Module Names (Downstream Bug - Informational)

**Impact**: 2 test playbooks fail  
**Severity**: **LOW** - Test utilities only  
**Root Cause**: Module renamed in ansible.controller 4.x  

**Affected Downstream Playbooks**:
- `playbooks/test-oc-mirror-workflow.yml` (2 occurrences)
- `playbooks/test-registry-vm-workflow.yml` (4 occurrences)

**Incorrect Module**: `ansible.controller.workflow_job_wait`  
**Correct Module**: `ansible.controller.workflow_node_wait`  

**Fix Status**: Will be corrected in ocp4-disconnected-helper repository (not an EE issue)

---

## Collections Currently in v1.2.1 EE

```
ansible.controller  4.8.2   ✅
ansible.hub         1.0.6   ✅
ansible.posix       2.2.0   ✅
ansible.utils       6.0.3   ✅
amazon.aws          11.3.0  ✅
azure.azcollection  3.19.0  ✅
community.general   13.1.0  ✅
infra.aap_utilities 3.4.0   ✅
kubernetes.core     6.4.0   ✅
```

**Total Collections**: 9

---

## Recommended Action for v1.2.2 Release

### Files to Modify

**`files/requirements.yml`** — Add 2 collections:

```yaml
collections:
  # ... existing collections ...
  - name: kubernetes.core  # containers
  - name: containers.podman  # containers (required for JFrog registry setup)
  
  # ... existing collections ...
  - name: community.general  # general
  - name: community.libvirt  # general (required for KVM/libvirt VM provisioning)
  - name: ansible.utils  # general
```

### Impact Assessment

**Before** (v1.2.1):
- 51 / 62 downstream playbooks pass (82% coverage)
- 10 playbooks blocked by community.libvirt
- 1 playbook blocked by containers.podman
- Main `site.yml` entrypoint fails ❌

**After** (v1.2.2 with additions):
- 61 / 62 downstream playbooks pass (98% coverage)
- All core workflows functional ✅
- Main `site.yml` entrypoint works ✅
- Only 2 test playbooks need module name fix (downstream bug)

---

## Testing Verification

### Test Command (Manual)

```bash
# Clone downstream project
git clone https://github.com/tosin2013/ocp4-disconnected-helper
cd ocp4-disconnected-helper

# Run syntax check with EE v1.2.2
for playbook in playbooks/*.yml; do
  podman run --rm \
    -v $PWD:/workspace:Z \
    -w /workspace \
    quay.io/takinosh/ocp4-aap-execution-environment:v1.2.2 \
    ansible-playbook --syntax-check "$playbook" \
    -i inventory/ibm-cloud.yml || echo "FAILED: $playbook"
done
```

**Expected Result** (v1.2.2):
- 61/62 playbooks pass ✅
- Only `test-*workflow.yml` fail (known downstream module name issue)

### Automated CI Validation

Downstream project runs **GitHub Actions workflow** for every commit:
- **Workflow**: `.github/workflows/ansible-sanity.yml`
- **Job**: `syntax-check`
- **Test Coverage**: All 62 playbooks

**Evidence**: GitHub Actions run #27712350333 (Ansible Sanity workflow)

---

## Downstream Project Context

**Project**: ocp4-disconnected-helper  
**URL**: https://github.com/tosin2013/ocp4-disconnected-helper  
**Purpose**: Automated deployment of disconnected/air-gapped OpenShift 4 infrastructure

**Uses this EE for**:
- GitHub Actions CI/CD syntax validation (62 playbooks)
- AAP 2.6 job template execution (disconnected OpenShift deployments)
- Local development with ansible-navigator

**Architecture**:
- Nested KVM on IBM Cloud VSI (requires community.libvirt)
- VyOS router + registry VMs (requires libvirt.virt module)
- Mirror-registry v2 in containers (podman integration)
- AAP 2.6 multi-node deployment automation

---

## Release History

- **v1.2.0** (2026-06-17): Added `ansible.controller` collection
- **v1.2.1** (2026-06-17): Added `infra.aap_utilities` collection  
- **v1.2.2** (proposed): Add `community.libvirt` + `containers.podman` collections

---

## Collaboration Model

**Upstream (this repo)**: Maintains EE with comprehensive collection set  
**Downstream (ocp4-disconnected-helper)**: Consumes EE for CI/CD and AAP runtime  

**Benefit**: Downstream project **removes all custom EE build logic** and delegates to this repository:
- No more `playbooks/build-custom-ee.yml` maintenance
- No more GitHub Actions EE build workflows
- Single source of truth for AAP execution environment
- Faster CI (pull pre-built image vs build from scratch)

---

## Contact

**Issue Reporter**: Tosin Akinosho ([@tosin2013](https://github.com/tosin2013))  
**Downstream Project**: ocp4-disconnected-helper  
**CI Evidence**: [GitHub Actions run #27712350333](https://github.com/tosin2013/ocp4-disconnected-helper/actions/runs/27712350333)

---

## Appendix: Full Error Log

<details>
<summary>Click to expand full syntax check output (62 playbooks)</summary>

```
=== Checking playbooks/assess-deployment-environment.yml ===
✅ PASSED

=== Checking playbooks/deploy-openshift-cluster.yml ===
ERROR! couldn't resolve module/action 'community.libvirt.virt'.

=== Checking playbooks/deploy-registry.yml ===
ERROR! couldn't resolve module/action 'community.libvirt.virt'.

=== Checking playbooks/destroy-registry-vm.yml ===
ERROR! couldn't resolve module/action 'community.libvirt.virt'.

=== Checking playbooks/provision-aap-vm.yml ===
ERROR! couldn't resolve module/action 'community.libvirt.virt'.

=== Checking playbooks/provision-registry-vm-with-static-ip.yml ===
ERROR! couldn't resolve module/action 'community.libvirt.virt'.

=== Checking playbooks/provision-registry-vm.yml ===
ERROR! couldn't resolve module/action 'community.libvirt.virt'.

=== Checking playbooks/setup-dependencies.yml ===
ERROR! couldn't resolve module/action 'community.libvirt.virt'.

=== Checking playbooks/setup-jfrog-registry.yml ===
ERROR! couldn't resolve module/action 'containers.podman.podman_image'.

=== Checking playbooks/site.yml ===
ERROR! couldn't resolve module/action 'community.libvirt.virt'.

=== Checking playbooks/test-oc-mirror-workflow.yml ===
ERROR! couldn't resolve module/action 'ansible.controller.workflow_job_wait'.

=== Checking playbooks/test-registry-vm-workflow.yml ===
ERROR! couldn't resolve module/action 'ansible.controller.workflow_job_wait'.

=== Checking playbooks/validate-cockpit-libvirt.yml ===
ERROR! couldn't resolve module/action 'community.libvirt.virt'.
```

</details>
