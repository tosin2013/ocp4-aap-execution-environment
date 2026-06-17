# Using Custom Python Package Indexes

Configure custom Python package indexes for execution environments using the `PIP_INDEX_URL` environment variable.

## Overview

By default, `pip` uses PyPI (https://pypi.org) to install Python packages. In enterprise or air-gapped environments, you may need to use:

- Internal PyPI mirrors
- Artifact repositories (Artifactory, Nexus)
- Red Hat-hosted package indexes
- Custom package servers

## Configuration Methods

### Method 1: PIP_INDEX_URL Build Argument (Recommended)

Set the index URL during the build process:

```yaml
# execution-environment.yml
version: 3

build_arg_defaults:
  PIP_INDEX_URL: https://your-pypi-mirror.company.com/simple
  PIP_TRUSTED_HOST: your-pypi-mirror.company.com

images:
  base_image:
    name: 'registry.redhat.io/ansible-automation-platform-26/ee-minimal-rhel9:latest'

dependencies:
  python: files/requirements.txt
```

Build with the custom index:

```bash
ansible-builder build \
  --build-arg PIP_INDEX_URL=https://your-pypi-mirror.company.com/simple \
  --build-arg PIP_TRUSTED_HOST=your-pypi-mirror.company.com \
  -t custom-ee:latest
```

### Method 2: pip.conf in Additional Build Files

Create a pip configuration file:

```ini
# files/pip.conf
[global]
index-url = https://your-pypi-mirror.company.com/simple
trusted-host = your-pypi-mirror.company.com
```

Reference it in `execution-environment.yml`:

```yaml
additional_build_files:
  - src: files/pip.conf
    dest: configs

additional_build_steps:
  prepend_final:
    - COPY _build/configs/pip.conf /etc/pip.conf
```

### Method 3: Environment Variable at Runtime

Set the index URL when running the execution environment:

```bash
# Using podman
podman run -it --rm \
  -e PIP_INDEX_URL=https://your-pypi-mirror.company.com/simple \
  quay.io/takinosh/ocp4-aap-execution-environment:latest \
  pip install some-package

# Using ansible-navigator
ansible-navigator run playbook.yml \
  --set-environment-variable PIP_INDEX_URL=https://your-pypi-mirror.company.com/simple
```

## Red Hat Package Index

For Red Hat subscribed systems, use the official Red Hat Python package index:

```yaml
build_arg_defaults:
  PIP_INDEX_URL: https://pypi.org/simple
  PIP_EXTRA_INDEX_URL: https://username:password@pypi.org/simple
```

Reference: [Managing Python Dependencies in Ansible Execution Environments](https://developers.redhat.com/articles/2025/01/27/how-manage-python-dependencies-ansible-execution-environments#python_dependency_management)

## Use Cases

### Air-Gapped Environments

Mirror PyPI packages to an internal server:

```bash
# 1. Download packages on internet-connected machine
pip download -r requirements.txt -d /tmp/packages

# 2. Set up simple HTTP server
python3 -m http.server --directory /tmp/packages 8080

# 3. Point EE build to local server
ansible-builder build --build-arg PIP_INDEX_URL=http://mirror-server:8080/simple
```

### JFrog Artifactory Integration

```yaml
build_arg_defaults:
  PIP_INDEX_URL: https://artifactory.company.com/artifactory/api/pypi/pypi-remote/simple
  PIP_TRUSTED_HOST: artifactory.company.com
```

With authentication:

```bash
# Use API token
ansible-builder build \
  --build-arg PIP_INDEX_URL=https://user:api-token@artifactory.company.com/artifactory/api/pypi/pypi-remote/simple
```

### Nexus Repository Manager

```yaml
build_arg_defaults:
  PIP_INDEX_URL: https://nexus.company.com/repository/pypi-proxy/simple
  PIP_TRUSTED_HOST: nexus.company.com
```

## Multiple Package Indexes

Use both primary and fallback indexes:

```yaml
build_arg_defaults:
  PIP_INDEX_URL: https://primary-mirror.company.com/simple
  PIP_EXTRA_INDEX_URL: https://fallback-mirror.company.com/simple https://pypi.org/simple
```

## Optional Configuration File

Create `files/optional-configs/pip-config.env` for easy switching:

```bash
# files/optional-configs/pip-config.env
export PIP_INDEX_URL=https://your-pypi-mirror.company.com/simple
export PIP_TRUSTED_HOST=your-pypi-mirror.company.com
export PIP_EXTRA_INDEX_URL=https://pypi.org/simple
```

Load during builds:

```bash
source files/optional-configs/pip-config.env
make build
```

## Verification

Test that the custom index is being used:

```bash
# Check pip configuration
podman run --rm quay.io/takinosh/ocp4-aap-execution-environment:latest \
  pip config list

# Attempt package installation with verbose output
podman run --rm \
  -e PIP_INDEX_URL=https://your-mirror.com/simple \
  quay.io/takinosh/ocp4-aap-execution-environment:latest \
  pip install --verbose some-package
```

## Troubleshooting

### SSL Certificate Errors

```bash
# Disable SSL verification (not recommended for production)
PIP_TRUSTED_HOST=your-mirror.com

# Or provide custom CA certificate
additional_build_steps:
  prepend_final:
    - COPY _build/configs/ca-cert.crt /etc/pki/ca-trust/source/anchors/
    - RUN update-ca-trust
```

### Authentication Failures

Ensure credentials are properly URL-encoded:

```bash
# Special characters in passwords need encoding
# Example: password with @ symbol
PIP_INDEX_URL=https://user:p%40ssword@mirror.com/simple
```

### Package Not Found

Verify the package exists in your mirror:

```bash
curl https://your-mirror.com/simple/ansible-core/
```

## Security Considerations

1. **Avoid embedding credentials in version control**
   - Use build arguments or environment variables
   - Store in CI/CD secrets

2. **Use HTTPS for package indexes**
   - Prevents man-in-the-middle attacks
   - Ensures package integrity

3. **Verify package signatures**
   - Enable package verification when available
   - Use trusted mirrors only

## References

- [pip Configuration Documentation](https://pip.pypa.io/en/stable/topics/configuration/)
- [Managing Python Dependencies in Ansible EEs](https://developers.redhat.com/articles/2025/01/27/how-manage-python-dependencies-ansible-execution-environments)
- [ansible-builder Documentation](https://ansible.readthedocs.io/projects/builder/)

## Related Documentation

- [Build Locally](build-locally.md) - Local build procedures
- [Optional Configs and Secrets](../reference/optional-configs-and-secrets.md) - Configuration files
- [CI/CD Integration](ci-cd.md) - Automated builds
