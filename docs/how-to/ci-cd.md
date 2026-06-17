---
title: CI/CD with GitHub Actions and Tekton
description: Automate EE builds and publishes to Quay using Podman in GitHub Actions or Tekton.
---

# CI/CD with GitHub Actions and Tekton

This guide shows how to automate building and publishing the Execution Environment (EE) to Quay using GitHub Actions, and how to adapt for Tekton.

## GitHub Actions (recommended, Podman-first)

Prerequisites:
- Quay repo created (e.g., `quay.io/<org>/<repo>`).
- Secrets in your GitHub repo: `QUAY_USERNAME`, `QUAY_PASSWORD`, `ANSIBLE_HUB_TOKEN`.
- Optional (for Red Hat content): `REDHAT_REGISTRY_USERNAME`, `REDHAT_REGISTRY_PASSWORD`.

Steps:
- Edit `.github/workflows/build-and-push.yml` and set `TARGET_NAME` (e.g., `yourorg/ansible-ee-minimal`) and `TARGET_TAG`.
- Push to `main` or run via “Run workflow”. The job will:
  - Install Podman, `ansible-builder`, and `ansible-navigator`.
  - Login to `registry.redhat.io` (if credentials provided) and `quay.io` with Podman.
  - `make build` → `make test` → `make publish` using `CONTAINER_ENGINE=podman`.

Verification:
- Pull from another machine: `podman pull quay.io/<org>/<repo>:<tag>`.

Outcome:
- On push/PR, the workflow builds, tests, and publishes the image to Quay (on main).

## Tekton (OpenShift Pipelines)

Approach: generate the build context with `ansible-builder create`, then build/push with Buildah.

Example Task (inline):
```yaml
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: ee-buildah
spec:
  params:
    - name: image
    - name: tag
  workspaces:
    - name: source
  steps:
    - name: create-context
      image: quay.io/ansible/ansible-builder:latest
      workingDir: $(workspaces.source.path)
      script: |
        #!/usr/bin/env bash
        set -euxo pipefail
        ansible-builder create
    - name: build-push
      image: quay.io/buildah/stable
      securityContext:
        privileged: true
      workingDir: $(workspaces.source.path)
      env:
        - name: REGISTRY_AUTH_FILE
          value: /auth/auth.json
      volumeMounts:
        - name: registry-auth
          mountPath: /auth
      script: |
        #!/usr/bin/env bash
        set -euxo pipefail
        buildah bud -f context/Containerfile -t $(params.image):$(params.tag) context
        buildah push $(params.image):$(params.tag)
  volumes:
    - name: registry-auth
      secret:
        secretName: registry-auth
```

Notes:
- Provide a pull/push secret named `registry-auth` containing an `auth.json` for both `registry.redhat.io` and `quay.io`.
- The `build-push` step needs `privileged` SCC (cluster policy) to run Buildah.
- Use a `Pipeline` to wire this task with a `git-clone` step and parameters (image, tag).

Minimal PipelineRun example:
```yaml
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  name: ee-build-run
spec:
  pipelineSpec:
    workspaces:
      - name: ws
    params:
      - name: image
      - name: tag
    tasks:
      - name: clone
        taskRef:
          name: git-clone
          kind: ClusterTask
        workspaces:
          - name: output
            workspace: ws
        params:
          - name: url
            value: https://github.com/yourorg/ansible-execution-environment.git
      - name: build
        runAfter: [clone]
        taskRef:
          name: ee-buildah
        workspaces:
          - name: source
            workspace: ws
        params:
          - name: image
            value: quay.io/yourorg/ansible-ee-minimal
          - name: tag
            value: v5
```

Troubleshooting:
- Missing packages at build time → add to `files/bindep.txt`.
- Galaxy/Hub access issues → verify `ANSIBLE_HUB_TOKEN` and registry auth.
- SELinux/permissions in Tekton → ensure privileged SCC or use OpenShift Pipelines best practices.

## Using This EE in Downstream CI/CD Workflows

This custom AAP execution environment can be used in **other projects** for CI/CD validation without requiring Automation Hub credentials in each repository.

### Use Case: Validate AAP Playbooks in GitHub Actions

**Problem:** AAP-specific playbooks (using `ansible.controller`, `ansible.hub` collections) cannot be validated in standard CI because:
- Collections require Automation Hub authentication
- Installing collections requires storing `ANSIBLE_HUB_TOKEN` in every repository
- GitHub Actions runners don't have AAP/AWX installed

**Solution:** Pull the pre-built EE from Quay and run syntax checks inside the container.

**Example:** [ocp4-disconnected-helper Issue #37](https://github.com/tosin2013/ocp4-disconnected-helper/issues/37)

```yaml
name: AAP Playbook Validation
on: [push, pull_request]

jobs:
  syntax-check:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v6

      - name: Pull Custom AAP Execution Environment
        run: |
          podman pull quay.io/takinosh/ocp4-aap-execution-environment:latest

      - name: Validate all playbooks
        run: |
          for playbook in playbooks/*.yml; do
            echo "Checking $playbook..."
            podman run --rm \
              -v $PWD:/workspace:Z \
              -w /workspace \
              quay.io/takinosh/ocp4-aap-execution-environment:latest \
              ansible-playbook --syntax-check "$playbook" \
              -i inventory/hosts.yml \
              || exit 1
          done
```

### Benefits

✅ **Zero credential management** - No need to store Ansible Hub token in downstream repos  
✅ **Complete coverage** - All AAP playbooks validated (no skipping)  
✅ **Consistent environment** - Same EE in CI and AAP runtime  
✅ **Faster CI** - Pull pre-built image (~3GB, 30-60s) vs pip install + collection downloads  
✅ **Dependency parity** - Exact same Ansible collections, Python packages, and binaries

### Collections Available in This EE

When you use this EE in your CI, these collections are available without additional installation:

- `ansible.controller` - AAP job templates, inventories, credentials
- `ansible.hub` - AAP configuration automation
- `ansible.platform` - AAP infrastructure management
- `kubernetes.core` - OpenShift/K8s resource management (includes oc/kubectl binaries)
- `amazon.aws` - AWS automation
- `azure.azcollection` - Azure automation
- `community.general` - Common utilities
- `ansible.utils` - Network and data utilities

### Advanced CI Patterns

**Run playbook tests:**
```yaml
- name: Test playbook execution (dry-run)
  run: |
    podman run --rm \
      -v $PWD:/workspace:Z \
      -w /workspace \
      -e ANSIBLE_FORCE_COLOR=1 \
      quay.io/takinosh/ocp4-aap-execution-environment:latest \
      ansible-playbook playbooks/configure-aap.yml \
        --check \
        --diff \
        -i inventory/test.yml
```

**Use with ansible-navigator:**
```yaml
- name: Install ansible-navigator
  run: pip install ansible-navigator

- name: Run playbook with navigator
  run: |
    ansible-navigator run playbooks/deploy.yml \
      --execution-environment-image quay.io/takinosh/ocp4-aap-execution-environment:latest \
      --mode stdout \
      -i inventory/production.yml
```

**Verify OpenShift tools available:**
```yaml
- name: Verify oc and kubectl binaries
  run: |
    podman run --rm \
      quay.io/takinosh/ocp4-aap-execution-environment:latest \
      oc version --client

    podman run --rm \
      quay.io/takinosh/ocp4-aap-execution-environment:latest \
      oc-mirror version
```

### Community Reusability

This pattern is reusable for **any project** that needs to validate AAP playbooks in CI without:
- Setting up AAP/AWX instances in CI
- Managing Automation Hub credentials in multiple repos
- Building custom EEs per project

**Example use cases:**
- AAP configuration-as-code repositories
- OpenShift deployment automation
- Multi-cloud infrastructure-as-code with AAP orchestration
- GitOps workflows with AAP as the automation engine

### Performance Considerations

**Image Size:** ~3GB (acceptable for CI caching)  
**Pull Time:** 30-60 seconds on first run (cached on subsequent runs)  
**Execution Time:** Syntax checks typically < 5 seconds per playbook  
**Total CI Time:** < 5 minutes for 20+ playbooks (including image pull)

### Related Documentation

- [Getting Started Tutorial](../tutorials/getting-started.md) - Build your own custom EE
- [Testing Execution Environment](testing-execution-environment.md) - Test EE locally
- [Release Process](release-process.md) - How new versions are published to Quay

### References

- **Upstream Issue:** [ocp4-disconnected-helper #37](https://github.com/tosin2013/ocp4-disconnected-helper/issues/37) - Integration example
- **Quay Repository:** [quay.io/takinosh/ocp4-aap-execution-environment](https://quay.io/repository/takinosh/ocp4-aap-execution-environment)
- **Source Repository:** [github.com/tosin2013/ocp4-aap-execution-environment](https://github.com/tosin2013/ocp4-aap-execution-environment)
