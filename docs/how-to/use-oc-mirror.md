# Using oc-mirror in Execution Environments

This execution environment includes the `oc-mirror` binary for mirroring OpenShift content to disconnected environments.

## What is oc-mirror?

`oc-mirror` is a CLI tool that mirrors OpenShift Container Platform (OCP) images, Operators, and helm charts to a mirror registry for use in disconnected or air-gapped environments.

## Prerequisites

- Access to a mirror registry (e.g., Quay, Harbor, internal registry)
- Mirror registry credentials configured
- Sufficient storage for mirrored content

## Basic Usage

### 1. Create Image Set Configuration

Create `imageset-config.yaml`:

```yaml
apiVersion: mirror.openshift.io/v1alpha2
kind: ImageSetConfiguration
metadata:
  name: ocp-mirror-config
mirror:
  platform:
    channels:
      - name: stable-4.21
        minVersion: 4.21.0
        maxVersion: 4.21.9
  operators:
    - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.21
      packages:
        - name: advanced-cluster-management
        - name: openshift-gitops-operator
```

### 2. Mirror Content

```bash
# Run oc-mirror inside the execution environment
ansible-navigator exec --  oc-mirror \
  --config=imageset-config.yaml \
  file://mirror-output

# Or using podman directly
podman run -it --rm \
  -v $(pwd):/workspace:Z \
  quay.io/takinosh/ocp4-aap-execution-environment:latest \
  oc-mirror --config=/workspace/imageset-config.yaml file:///workspace/mirror-output
```

### 3. Publish to Mirror Registry

```bash
# Push mirrored content to your registry
oc-mirror --from=mirror-output docker://your-mirror-registry.com/ocp4
```

## Common Use Cases

### Mirror Specific OpenShift Version

```yaml
mirror:
  platform:
    channels:
      - name: stable-4.21
        minVersion: 4.21.9
        maxVersion: 4.21.9  # Specific version only
```

### Mirror Operators for Disconnected AAP

```yaml
mirror:
  operators:
    - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.21
      packages:
        - name: ansible-automation-platform-operator
        - name: kubernetes-nmstate-operator
```

### Differential Mirroring (Updates Only)

```bash
# First mirror (full)
oc-mirror --config=imageset-config.yaml file://mirror-v1

# Subsequent mirror (differential - only new/updated images)
oc-mirror --config=imageset-config.yaml \
  --from=mirror-v1 \
  file://mirror-v2
```

## Integration with Ansible Playbooks

Use oc-mirror in your Ansible automation:

```yaml
---
- name: Mirror OpenShift content for disconnected environment
  hosts: localhost
  tasks:
    - name: Ensure imageset config exists
      ansible.builtin.copy:
        dest: /tmp/imageset-config.yaml
        content: |
          apiVersion: mirror.openshift.io/v1alpha2
          kind: ImageSetConfiguration
          mirror:
            platform:
              channels:
                - name: stable-4.21

    - name: Run oc-mirror
      ansible.builtin.command:
        cmd: >
          oc-mirror
          --config=/tmp/imageset-config.yaml
          file:///mnt/mirror-output
      register: mirror_result

    - name: Display mirror summary
      ansible.builtin.debug:
        var: mirror_result.stdout_lines
```

## Verification

Check that oc-mirror is available:

```bash
# Inside execution environment
oc-mirror version

# Expected output
Client Version: {version}
```

## Troubleshooting

### oc-mirror command not found

Ensure you're using the execution environment with oc-mirror included (v1.2.0+):

```bash
podman run -it --rm quay.io/takinosh/ocp4-aap-execution-environment:latest which oc-mirror
# Should return: /usr/local/bin/oc-mirror
```

### Permission denied errors

Ensure volumes are mounted with `:Z` (SELinux context) when using podman:

```bash
podman run -v $(pwd):/workspace:Z ...
```

### Insufficient storage

oc-mirror requires significant disk space. Check available space:

```bash
df -h /path/to/mirror-output
```

## References

- [oc-mirror Official Documentation](https://docs.openshift.com/container-platform/latest/installing/disconnected_install/installing-mirroring-disconnected.html)
- [Mirroring images for a disconnected installation](https://docs.openshift.com/container-platform/latest/installing/disconnected_install/installing-mirroring-installation-images.html)
- [ImageSetConfiguration API Reference](https://docs.openshift.com/container-platform/latest/installing/disconnected_install/installing-mirroring-disconnected.html#oc-mirror-imageset-config-params_installing-mirroring-disconnected)

## Related Documentation

- [Enable Kubernetes and OpenShift](enable-kubernetes-openshift.md) - oc/kubectl configuration
- [CI/CD Integration](ci-cd.md) - Automating image builds
- [Advanced Usage](advanced-usage.md) - Customization options
