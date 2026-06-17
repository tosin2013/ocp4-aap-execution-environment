# Quick Start Guide

Get started with the AAP Execution Environment in 5 minutes.

## What is This?

A ready-to-use container image for running Ansible Automation Platform playbooks with:
- ✅ **AAP 2.6** collections pre-installed
- ✅ **OpenShift/Kubernetes** tools (oc, kubectl, oc-mirror)
- ✅ **Security scanned** with Quay.io + Trivy
- ✅ **Signed images** with cosign
- ✅ **Disconnected environment** support

Perfect for: OpenShift automation, AAP workflows, CI/CD pipelines, air-gapped deployments.

---

## Pull the Image

```bash
# Latest release (v1.2.0)
podman pull quay.io/takinosh/ocp4-aap-execution-environment:v1.2.0

# Or always use latest
podman pull quay.io/takinosh/ocp4-aap-execution-environment:latest
```

**Image size:** ~1.2GB  
**Registry:** https://quay.io/repository/takinosh/ocp4-aap-execution-environment

---

## Verify What's Included

```bash
# Check AAP version
podman run --rm quay.io/takinosh/ocp4-aap-execution-environment:v1.2.0 \
  ansible-navigator --version

# List installed collections
podman run --rm quay.io/takinosh/ocp4-aap-execution-environment:v1.2.0 \
  ansible-galaxy collection list

# Verify OpenShift tools
podman run --rm quay.io/takinosh/ocp4-aap-execution-environment:v1.2.0 \
  oc version --client

podman run --rm quay.io/takinosh/ocp4-aap-execution-environment:v1.2.0 \
  oc-mirror version
```

**Included Collections (8):**
- ansible.platform
- ansible.controller
- ansible.utils
- ansible.posix
- containers.podman
- community.general
- kubernetes.core
- redhat.openshift

---

## Run Your First Playbook

### Option 1: With ansible-navigator (Recommended)

```bash
# Create a simple playbook
cat > test.yml <<'EOF'
---
- name: Test AAP Execution Environment
  hosts: localhost
  gather_facts: yes
  tasks:
    - name: Show Ansible version
      debug:
        msg: "Running with {{ ansible_version.full }}"
    
    - name: Show available collections
      shell: ansible-galaxy collection list
      register: collections
    
    - name: Display collections
      debug:
        var: collections.stdout_lines
EOF

# Run with ansible-navigator
ansible-navigator run test.yml \
  --execution-environment-image quay.io/takinosh/ocp4-aap-execution-environment:v1.2.0 \
  --mode stdout
```

### Option 2: Interactive Shell

```bash
# Enter the container interactively
podman run -it --rm quay.io/takinosh/ocp4-aap-execution-environment:v1.2.0 /bin/bash

# Inside the container:
ansible-playbook --version
ansible-galaxy collection list
oc version --client
```

### Option 3: Direct Command

```bash
# Run a single command
podman run --rm \
  -v $(pwd):/ansible:Z \
  -w /ansible \
  quay.io/takinosh/ocp4-aap-execution-environment:v1.2.0 \
  ansible-playbook playbook.yml
```

---

## Use Cases

### 1️⃣ OpenShift/Kubernetes Automation

```yaml
# playbook.yml
---
- name: Manage OpenShift Resources
  hosts: localhost
  tasks:
    - name: Get cluster version
      kubernetes.core.k8s_info:
        kind: ClusterVersion
      register: cluster_info
    
    - name: Show version
      debug:
        msg: "OpenShift {{ cluster_info.resources[0].status.desired.version }}"
```

**Run:**
```bash
ansible-navigator run playbook.yml \
  --execution-environment-image quay.io/takinosh/ocp4-aap-execution-environment:v1.2.0 \
  --mode stdout
```

### 2️⃣ Disconnected Environment (oc-mirror)

```bash
# Mirror OpenShift content for air-gapped environments
podman run --rm \
  -v $(pwd)/imageset-config.yaml:/config.yaml:Z \
  -v $(pwd)/mirror-output:/output:Z \
  quay.io/takinosh/ocp4-aap-execution-environment:v1.2.0 \
  oc-mirror --config /config.yaml file:///output
```

See: [docs/how-to/use-oc-mirror.md](docs/how-to/use-oc-mirror.md)

### 3️⃣ CI/CD Pipeline (GitHub Actions, Tekton)

```yaml
# .github/workflows/validate-playbooks.yml
jobs:
  validate:
    runs-on: ubuntu-latest
    container:
      image: quay.io/takinosh/ocp4-aap-execution-environment:v1.2.0
    steps:
      - uses: actions/checkout@v6
      - name: Syntax check
        run: ansible-playbook playbooks/*.yml --syntax-check
      - name: Lint
        run: ansible-lint playbooks/
```

See: [docs/how-to/ci-cd.md](docs/how-to/ci-cd.md)

### 4️⃣ Custom Python Package Index

```bash
# Use internal PyPI mirror
podman run --rm \
  -e PIP_INDEX_URL=https://artifactory.company.com/pypi/simple \
  quay.io/takinosh/ocp4-aap-execution-environment:v1.2.0 \
  pip list
```

See: [docs/how-to/custom-python-index.md](docs/how-to/custom-python-index.md)

---

## Common Workflows

### Mount Your Playbooks

```bash
# Mount current directory into container
podman run --rm \
  -v $(pwd):/ansible:Z \
  -w /ansible \
  quay.io/takinosh/ocp4-aap-execution-environment:v1.2.0 \
  ansible-playbook site.yml -i inventory
```

### Use Environment Variables

```bash
# Pass credentials via environment
podman run --rm \
  -e ANSIBLE_HOST_KEY_CHECKING=False \
  -e KUBECONFIG=/kubeconfig \
  -v $(pwd):/ansible:Z \
  -v ~/.kube/config:/kubeconfig:Z \
  quay.io/takinosh/ocp4-aap-execution-environment:v1.2.0 \
  ansible-playbook k8s-playbook.yml
```

### Use Ansible Vault

```bash
# Mount vault password file
podman run --rm \
  -v $(pwd):/ansible:Z \
  -v ~/.vault_pass:/vault_pass:Z \
  -w /ansible \
  quay.io/takinosh/ocp4-aap-execution-environment:v1.2.0 \
  ansible-playbook --vault-password-file=/vault_pass playbook.yml
```

---

## Verify Image Security

### Check Vulnerability Scan Results

Visit Quay.io security tab:
```
https://quay.io/repository/takinosh/ocp4-aap-execution-environment?tab=tags
```

Click on `v1.2.0` tag → "Security Scan" tab to see vulnerability report.

### Verify Image Signature (if signed)

```bash
# Install cosign
# https://docs.sigstore.dev/cosign/installation/

# Verify signature (if COSIGN_PRIVATE_KEY was configured)
cosign verify --key cosign.pub \
  quay.io/takinosh/ocp4-aap-execution-environment:v1.2.0
```

See: [docs/how-to/sign-and-verify-images.md](docs/how-to/sign-and-verify-images.md)

---

## Troubleshooting

### Image Pull Fails

**Error:** `unauthorized: access to the requested resource is not authorized`

**Solution:** The repository is public, but you may need to log in to Quay.io:
```bash
podman login quay.io
```

### Permission Denied

**Error:** `Permission denied` when mounting volumes

**Solution:** Add `:Z` flag for SELinux contexts:
```bash
-v $(pwd):/ansible:Z
```

### Collection Not Found

**Error:** `Collection not found`

**Solution:** Verify collection is installed:
```bash
podman run --rm quay.io/takinosh/ocp4-aap-execution-environment:v1.2.0 \
  ansible-galaxy collection list | grep <collection-name>
```

If missing, see: [docs/how-to/advanced-usage.md](docs/how-to/advanced-usage.md) for adding collections

---

## Next Steps

### Learn More

- 📖 **Full Documentation:** [docs/](docs/) - Complete Diátaxis framework
- 🎓 **Tutorial:** [Upgrading to v1.2.0](docs/tutorials/upgrading-to-v1.2.0.md)
- 🔧 **How-To Guides:** [docs/how-to/](docs/how-to/)
- 📚 **Reference:** [docs/reference/](docs/reference/)

### Advanced Topics

- [Build Your Own EE](docs/how-to/build-locally.md) - Customize this image
- [Windows Support](docs/how-to/add-windows-support.md) - Add WinRM/Kerberos
- [Troubleshooting](docs/how-to/troubleshoot-ee-builds.md) - Common issues

### Join the Community

- 🐛 **Report Issues:** https://github.com/tosin2013/ocp4-aap-execution-environment/issues
- 💬 **Discussions:** GitHub Discussions (coming soon)
- 📝 **Contribute:** Pull requests welcome!

---

## Version Information

**Current Release:** v1.2.0 (2026-06-17)  
**Base Image:** AAP 2.6 (ansible-automation-platform-26/ee-minimal-rhel9)  
**Python:** 3.11  
**Ansible Core:** 2.21.0  

**Previous Versions:**
- `v1.1.0` - AAP 2.5, OpenShift 4.21
- `v1.0.0` - Initial release

See [CHANGELOG.md](CHANGELOG.md) for full release history.

---

## Support

**Supported Platforms:**
- ✅ Red Hat Enterprise Linux 9
- ✅ Fedora 38+
- ✅ Ubuntu 22.04+ (with podman)
- ✅ macOS (with podman)

**Supported AAP Versions:**
- ✅ AAP 2.6 (current)
- ⚠️ AAP 2.5 (deprecated, use v1.1.0)

**Architecture:**
- ✅ x86_64 (amd64)
- ❌ aarch64 (arm64) - planned for v1.3.0

---

## Quick Reference Card

```bash
# Pull
podman pull quay.io/takinosh/ocp4-aap-execution-environment:v1.2.0

# Verify
podman run --rm <image> ansible-navigator --version

# Run playbook
ansible-navigator run playbook.yml --execution-environment-image <image> --mode stdout

# Interactive shell
podman run -it --rm <image> /bin/bash

# Mount playbooks
podman run --rm -v $(pwd):/ansible:Z -w /ansible <image> ansible-playbook site.yml

# Check collections
podman run --rm <image> ansible-galaxy collection list

# OpenShift tools
podman run --rm <image> oc version --client
podman run --rm <image> oc-mirror version
```

**Image:** `quay.io/takinosh/ocp4-aap-execution-environment:v1.2.0`

---

**Need help?** Check [docs/how-to/troubleshoot-ee-builds.md](docs/how-to/troubleshoot-ee-builds.md) or open an issue!
