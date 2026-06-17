# ADR-0009: Security Scanning Strategy

**Status:** Accepted  
**Date:** 2026-06-17  
**Deciders:** Development Team  
**Tags:** security, scanning, vulnerabilities, hardening

## Context

Container images can contain vulnerabilities in:
- Base operating system packages (RHEL 9)
- Python packages (pip dependencies)
- System libraries and binaries
- Third-party tools (oc, kubectl, oc-mirror)

We need an automated vulnerability scanning strategy that:
- Integrates with our CI/CD pipeline
- Provides actionable vulnerability reports
- Works with Quay.io registry (our current image hosting)
- Supports both local development and production scanning
- Aligns with enterprise security requirements

## Decision

We will implement a **dual-scanning approach**:

### Primary Scanner: Quay.io Security Scanner

Use Quay.io's built-in Clair-based vulnerability scanner as the primary scanning method.

**Rationale:**
- Already integrated with our Quay.io registry
- Automatic scanning on every push
- Web-based vulnerability dashboard
- No additional infrastructure required
- Red Hat supported for RHEL-based images
- Comprehensive CVE database

**Implementation:**
```bash
make scan  # Push to Quay and retrieve vulnerability report
```

### Secondary Scanner: Trivy (Local Development)

Use Trivy for local pre-push scanning during development.

**Rationale:**
- Fast local scanning without pushing to registry
- Open-source and widely adopted
- Supports multiple vulnerability databases
- Can scan during PR reviews
- Lightweight and easy to install

**Implementation:**
```bash
make scan-local  # Scan local image with Trivy
```

## Scanning Workflow

### Development Workflow

1. **Build image locally:**
   ```bash
   make build
   ```

2. **Scan locally with Trivy:**
   ```bash
   make scan-local
   ```

3. **Fix critical/high vulnerabilities**

4. **Push to Quay for full scan:**
   ```bash
   make publish
   make scan
   ```

### CI/CD Workflow

1. **Build image in GitHub Actions**
2. **Push to Quay.io**
3. **Wait for Quay security scan (30s)**
4. **Retrieve scan results via API**
5. **Fail pipeline if critical vulnerabilities found**

## Vulnerability Severity Handling

**Critical Severity:**
- Block releases
- Must be addressed before production deployment
- Exceptions require security team approval

**High Severity:**
- Document and track
- Address in next release cycle
- Can proceed to production with documented risk acceptance

**Medium/Low Severity:**
- Track in backlog
- Address as part of regular dependency updates
- No release blocking

## Scan Frequency

**Automated Scans:**
- On every push to Quay.io registry
- On every PR merge (CI/CD pipeline)
- Weekly scheduled scans of `:latest` tag

**Manual Scans:**
- Before major version releases
- After critical CVE announcements
- When updating base image or major dependencies

## Vulnerability Remediation Process

1. **Identify vulnerability:** Scan reports or CVE notifications
2. **Assess impact:** Determine if vulnerability affects our use case
3. **Remediate:**
   - Update affected package (preferred)
   - Remove affected package (if not needed)
   - Document exception with justification (if no fix available)
4. **Re-scan:** Verify fix with `make scan-local` and `make scan`
5. **Document:** Update CHANGELOG and security notes

## Consequences

### Positive

- Proactive vulnerability detection before production
- Automated scanning reduces manual security review burden
- Dual-scanner approach catches more vulnerabilities
- Quay.io integration provides historical vulnerability tracking
- Trivy enables fast local feedback loop
- Aligns with DevSecOps best practices
- Supports compliance requirements (NIST, PCI-DSS, etc.)

### Negative

- Quay scanning requires pushing images (slower feedback)
- False positives may occur (requires manual review)
- Trivy installation required for local scanning
- Scan results may vary between Clair (Quay) and Trivy databases
- May delay releases when critical vulnerabilities found

### Neutral

- Adds ~30-60 seconds to CI/CD pipeline (scan time)
- Requires security team to define vulnerability acceptance criteria
- Makefile complexity increased slightly

## Alternatives Considered

### Snyk Container Scanner

**Pros:**
- Deep integration with development workflow
- Excellent CLI and web interface
- Good Python dependency scanning

**Cons:**
- Requires separate subscription
- Additional infrastructure to maintain
- Less integrated with Quay.io

**Rejected because:** Quay.io scanner is sufficient and already available.

### Anchore Engine

**Pros:**
- Open-source
- Policy-based scanning
- Deep customization

**Cons:**
- Complex setup and maintenance
- Requires dedicated infrastructure
- Overkill for single-repository use case

**Rejected because:** Too complex for our needs; Trivy provides similar functionality with simpler setup.

### Red Hat Advanced Cluster Security (RHACS)

**Pros:**
- Enterprise-grade scanning
- Red Hat supported
- Integrates with OpenShift

**Cons:**
- Requires OpenShift cluster
- Enterprise license required
- Over-engineered for pre-production scanning

**Rejected because:** Not all users have RHACS; Quay.io scanner is more accessible.

## Implementation Notes

### Makefile Targets

**Primary target:**
```makefile
scan: # Scan image for vulnerabilities using Quay.io scanner
    # Push image to Quay
    # Wait for scan completion
    # Fetch and display results
```

**Secondary target:**
```makefile
scan-local: # Scan local image using Trivy
    # Check trivy installed
    # Run trivy on local image
    # Filter for HIGH/CRITICAL only
```

### CI/CD Integration

Add to `.github/workflows/build-and-push.yml`:

```yaml
- name: Security Scan
  if: startsWith(github.ref, 'refs/tags/v')
  run: make scan
  continue-on-error: true  # Don't block initially; move to false after baseline established
```

### Scan Results Storage

- Quay.io: Vulnerability reports stored in Quay UI (persistent)
- Trivy: Output to console (ephemeral)
- CI/CD: Scan results in GitHub Actions logs (90-day retention)

## References

- [Quay.io Security Scanning](https://docs.projectquay.io/use_quay.html#security-scanning)
- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [DevSecOps: Image scanning in your pipelines using quay.io scanner](https://www.redhat.com/sysadmin/using-quayio-scanner)
- [Using Snyk and Podman to scan container images](https://www.redhat.com/en/blog/using-snyk-and-podman-scan-container-images-development-deployment)
- [NIST Container Security Guide](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-190.pdf)

## Related ADRs

- [ADR-0002: Release Process and Tooling](0002-release-process.md) - Scanning integrated into release workflow
- [ADR-0004: Dependency Management Strategy](0004-dependency-management.md) - Dependabot updates help reduce vulnerabilities
