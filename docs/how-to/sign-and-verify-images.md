# Signing and Verifying Container Images

This guide covers signing and verifying execution environment images using cosign for supply chain security.

## Why Sign Images?

Image signing provides:
- **Authenticity verification** - Confirm images come from trusted sources
- **Integrity protection** - Detect tampering or modifications
- **Supply chain security** - Ensure images haven't been compromised
- **Compliance** - Meet security requirements (SLSA, NIST, etc.)

## Prerequisites

Install cosign:

```bash
# Linux
curl -O -L https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64
sudo mv cosign-linux-amd64 /usr/local/bin/cosign
sudo chmod +x /usr/local/bin/cosign

# macOS
brew install cosign

# Verify installation
cosign version
```

## Signing Methods

### Method 1: Key-Based Signing (Recommended for Automation)

**One-time setup - Generate key pair:**

```bash
make generate-signing-key
# You'll be prompted for a passphrase
# Creates: cosign.key (private) and cosign.pub (public)
```

**Important:** Add `cosign.key` to `.gitignore` to prevent accidental commits.

**Sign images after publishing:**

```bash
# Set passphrase (recommended)
export COSIGN_PASSWORD="your-secure-passphrase"

# Sign both version tag and latest
make sign
```

**Verify signatures:**

```bash
make verify-signature
```

### Method 2: Keyless Signing (OIDC-Based, No Key Management)

Uses Sigstore's public transparency log with OIDC authentication.

```bash
# Sign with keyless mode (prompts for OIDC auth)
make sign-keyless
```

Supports authentication via:
- GitHub
- Google
- Microsoft

**Pros:**
- No key management required
- Backed by transparency log
- Auditable via public Rekor log

**Cons:**
- Requires internet access
- Depends on external OIDC provider
- Transparency log is public

## Signing Workflow

### Local Signing

```bash
# 1. Build image
make build

# 2. Publish to registry
make publish

# 3. Sign images
export COSIGN_PASSWORD="your-passphrase"
make sign

# 4. Verify signatures
make verify-signature
```

### CI/CD Signing

Add to `.github/workflows/build-and-push.yml`:

```yaml
- name: Install cosign
  uses: sigstore/cosign-installer@v3

- name: Sign container images
  if: startsWith(github.ref, 'refs/tags/v')
  env:
    COSIGN_PASSWORD: ${{ secrets.COSIGN_PASSWORD }}
  run: |
    echo "${{ secrets.COSIGN_PRIVATE_KEY }}" > cosign.key
    make sign
    rm cosign.key
```

**Required GitHub Secrets:**
- `COSIGN_PRIVATE_KEY` - Content of cosign.key file
- `COSIGN_PASSWORD` - Passphrase for private key

## Verifying Signed Images

### Using Makefile

```bash
make verify-signature
```

### Using cosign CLI

```bash
# Verify with public key
cosign verify --key cosign.pub quay.io/takinosh/ocp4-aap-execution-environment:v1.2.0

# Verify keyless signatures
cosign verify quay.io/takinosh/ocp4-aap-execution-environment:v1.2.0
```

### In Kubernetes/OpenShift

Use admission controllers to enforce signature verification:

**Policy Controller (Sigstore):**

```yaml
apiVersion: policy.sigstore.dev/v1beta1
kind: ClusterImagePolicy
metadata:
  name: verify-aap-ee
spec:
  images:
  - glob: "quay.io/takinosh/ocp4-aap-execution-environment:*"
  authorities:
  - key:
      data: |
        -----BEGIN PUBLIC KEY-----
        <content of cosign.pub>
        -----END PUBLIC KEY-----
```

**Kyverno Policy:**

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: verify-aap-ee-signature
spec:
  validationFailureAction: enforce
  rules:
  - name: verify-signature
    match:
      resources:
        kinds:
        - Pod
    verifyImages:
    - image: "quay.io/takinosh/ocp4-aap-execution-environment:*"
      key: |-
        -----BEGIN PUBLIC KEY-----
        <content of cosign.pub>
        -----END PUBLIC KEY-----
```

## Key Management

### Storing Private Key Securely

**Local development:**
```bash
# Store in environment variable
export COSIGN_PASSWORD="passphrase"

# Use pass/gpg for secure storage
pass insert cosign/password
export COSIGN_PASSWORD=$(pass show cosign/password)
```

**CI/CD:**
- Store in GitHub Secrets
- Use HashiCorp Vault
- Use cloud KMS (AWS KMS, GCP KMS, Azure Key Vault)

### Key Rotation

When rotating keys:

```bash
# 1. Generate new key pair
mv cosign.key cosign.key.old
mv cosign.pub cosign.pub.old
make generate-signing-key

# 2. Sign new images with new key
make sign

# 3. Keep old public key for verifying old images
# Distribute new cosign.pub to consumers
```

## Advanced Signing

### Sign with Annotations

```bash
cosign sign --key cosign.key \
  -a release-version=v1.2.0 \
  -a build-date=$(date -u +%Y-%m-%dT%H:%M:%SZ) \
  -a git-sha=$(git rev-parse HEAD) \
  quay.io/takinosh/ocp4-aap-execution-environment:v1.2.0
```

### Sign with SBOM Attestations

```bash
# Generate SBOM
syft quay.io/takinosh/ocp4-aap-execution-environment:v1.2.0 -o spdx-json > sbom.json

# Attach SBOM as attestation
cosign attest --key cosign.key --predicate sbom.json \
  quay.io/takinosh/ocp4-aap-execution-environment:v1.2.0

# Verify attestation
cosign verify-attestation --key cosign.pub \
  quay.io/takinosh/ocp4-aap-execution-environment:v1.2.0
```

## Troubleshooting

### Signature Verification Fails

**Check registry accessibility:**
```bash
podman pull quay.io/takinosh/ocp4-aap-execution-environment:v1.2.0
```

**Verify public key matches:**
```bash
# Compare public key fingerprint
cosign public-key --key cosign.key
cat cosign.pub
```

**Check signature exists in registry:**
```bash
cosign triangulate quay.io/takinosh/ocp4-aap-execution-environment:v1.2.0
```

### Missing Signature

If `cosign verify` shows no signature:
```bash
# Re-sign the image
make sign

# Verify signature was uploaded
cosign verify --key cosign.pub quay.io/takinosh/ocp4-aap-execution-environment:v1.2.0
```

### Permission Denied

Ensure registry credentials are configured:
```bash
podman login quay.io
```

## Security Best Practices

1. **Never commit private keys** - Add `cosign.key` to `.gitignore`
2. **Use strong passphrases** - Minimum 20 characters, random
3. **Rotate keys annually** - Or after suspected compromise
4. **Distribute public keys securely** - Use HTTPS, verify checksums
5. **Enforce signature verification** - In production Kubernetes/OpenShift
6. **Use keyless signing for transparency** - When public auditability is required
7. **Sign all release images** - Make it mandatory in release process
8. **Verify before deployment** - Add verification to deployment pipelines

## References

- [Sigstore cosign Documentation](https://docs.sigstore.dev/cosign/overview/)
- [Signing Container Images with cosign](https://www.redhat.com/en/blog/signing-container-images-cosign)
- [Supply Chain Security with Sigstore](https://github.com/sigstore/cosign)
- [SLSA Framework](https://slsa.dev/)

## Related Documentation

- [CI/CD Integration](ci-cd.md) - Automated signing in pipelines
- [Security Scanning](../reference/tooling.md#security-scanning) - Complementary security practices
- [Release Process](release-process.md) - Signing as part of releases
