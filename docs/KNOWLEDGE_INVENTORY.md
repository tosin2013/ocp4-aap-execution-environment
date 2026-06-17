# Knowledge Inventory - AAP Execution Environment Builder v1.2.0

**Project:** ocp4-aap-execution-environment  
**Generated:** 2026-06-17  
**Purpose:** Comprehensive catalog of all project knowledge for Diátaxis documentation framework

## Sources Consulted

### Repository Files
- ✅ README.md
- ✅ CHANGELOG.md
- ✅ VERSION_COMPATIBILITY.md
- ✅ execution-environment.yml
- ✅ Makefile
- ✅ files/requirements.txt, requirements.yml, bindep.txt
- ✅ .github/workflows/*.yml

### Existing Documentation (40 files)
- ✅ 2 Tutorials
- ✅ 13 How-To Guides
- ✅ 4 Reference Docs
- ✅ 4 Explanation Docs
- ✅ 9 ADRs (0001-0009)
- ✅ 1 Security Checklist
- ✅ Index and navigation files

### Git History
- ✅ Last 30 commits analyzed
- ✅ Release history: v1.0.0 (2026-04-20), v1.1.0 (2026-04-21), v1.2.0 (2026-06-17)

### PMB Queries
- ⚠️ PMB queries skipped (per CLAUDE.md instructions - PMB only for personal/project history queries)

### ADR System
- ✅ 9 ADRs reviewed via file system

## Inventory: Facts, Procedures, Decisions, Concepts

### Project Identity

**Name:** ocp4-aap-execution-environment  
**Purpose:** Build custom AAP (Ansible Automation Platform) Execution Environments for OpenShift/Kubernetes environments using Makefile-driven workflow  
**License:** GNU General Public License v3.0  
**Author:** John Wadleigh  
**Maintainer:** Tosin Akinosho (tosin2013)

### Version History

**v1.2.0** (Current - 2026-06-17):
- AAP 2.6 base image support
- oc-mirror binary for disconnected environments
- PIP_INDEX_URL custom Python index support
- Vulnerability scanning (Quay.io + Trivy)
- Automated image signing (cosign)
- Updated dependencies: pip >=26.1.2, setuptools >=82.0.1, Node.js 24

**v1.1.0** (2026-04-21):
- OpenShift 4.21.9 support
- 8 ADRs established
- Dependabot integration
- Python 3.10+ enforcement
- Collection dependency validation
- 36-task functional test playbook

**v1.0.0** (2026-04-20):
- Initial baseline with AAP 2.5
- OpenShift 4.19 support
- Makefile build system
- GitHub Actions CI/CD

### Core Technologies

**Base Image:** registry.redhat.io/ansible-automation-platform-26/ee-minimal-rhel9:latest (AAP 2.6)  
**Container Runtime:** Podman  
**Build Tool:** ansible-builder  
**Testing Tool:** ansible-navigator  
**Documentation:** MkDocs with Material theme  
**CI/CD:** GitHub Actions  
**Registry:** Quay.io (quay.io/takinosh/ocp4-aap-execution-environment)

### Prerequisites

**Required:**
- Python 3.10+ (Python 3.11 recommended on RHEL 9)
- Podman
- Git
- jq, gettext (envsubst)

**Optional:**
- Red Hat Automation Hub token (for certified collections)
- Red Hat subscription (for RHSM-based installation)

### Included Collections (8 total)

1. **ansible.controller** - AAP job template/credential management
2. **ansible.hub** - AAP configuration management
3. **kubernetes.core** - Kubernetes/OpenShift resource management
4. **amazon.aws** - AWS automation
5. **azure.azcollection** - Azure automation
6. **community.general** - Common utilities
7. **ansible.utils** - Network and data utilities
8. **ansible.platform** - AAP infrastructure (dependency chain root)

### Included Binaries

- **oc** v4.21.9 - OpenShift CLI
- **kubectl** v1.34.1 - Kubernetes CLI
- **oc-mirror** - OpenShift mirroring tool for disconnected environments
- **podman** - Container management

### Architectural Decisions (ADRs)

**ADR-0001:** Semantic Versioning (MAJOR.MINOR.PATCH)  
**ADR-0002:** Release Process (Keep-a-Changelog, ADR links, GitHub Releases)  
**ADR-0003:** OpenShift Version Policy (stable-4.21, multi-version fallback)  
**ADR-0004:** Dependency Management (Dependabot weekly/monthly)  
**ADR-0005:** oc/kubectl Installation Strategy (Tarball Path B recommended)  
**ADR-0006:** Development Environment (Python 3.11+, venv-based)  
**ADR-0007:** AAP Collection Dependencies (ansible.platform → kubernetes.core chain)  
**ADR-0008:** Collection Dependency Validation (pre-build validation scripts)  
**ADR-0009:** Security Scanning Strategy (Dual: Quay.io + Trivy)

### Key Procedures

#### Build Workflow
1. `make setup` - Create venv, verify tools
2. Set `ANSIBLE_HUB_TOKEN` environment variable
3. `make build` - Build execution environment
4. `make test` - Run 36-task functional playbook
5. `make scan-local` - Scan for vulnerabilities locally
6. `make publish` - Push to Quay.io
7. `make scan` - Trigger Quay.io security scan
8. `make sign` - Sign images with cosign (releases only)

#### Testing Strategy
- **Functional:** 36 Ansible tasks across 8 collections
- **OpenShift Tooling:** 7 tests for oc/kubectl/oc-mirror
- **Collection Dependency:** Pre-build validation scripts
- **Security:** Dual scanning (Quay.io + Trivy)
- **Documentation:** MkDocs strict mode

#### Release Workflow
1. Update CHANGELOG.md (Keep-a-Changelog format)
2. Update VERSION_COMPATIBILITY.md
3. Merge Dependabot PRs
4. Run full test suite
5. Create git tag (vX.Y.Z)
6. Push tag to GitHub
7. CI/CD auto-builds, scans, signs, publishes
8. Create GitHub Release with notes

### Security Hardening

**Vulnerability Scanning:**
- Primary: Quay.io Clair scanner (automatic on push)
- Secondary: Trivy (local development)
- Severity Handling: Critical=block, High=track, Medium/Low=backlog

**Image Signing:**
- Method: cosign (key-based and keyless OIDC)
- Scope: All release tags (v*)
- CI/CD: Automated signing via GitHub Actions
- Verification: Kubernetes admission controllers supported

**Security Checklist:**
- docs/SECURITY_CHECKLIST.md provides verification steps
- Pre-release security audit required
- Vulnerability remediation tracked in CHANGELOG

### Configuration Options

**Environment Variables:**
- `ANSIBLE_HUB_TOKEN` - Required for certified collections
- `PIP_INDEX_URL` - Custom Python package index (optional)
- `OC_VERSION` - OpenShift CLI version (default: stable-4.21)
- `QUAY_USERNAME`, `QUAY_PASSWORD` - Registry authentication
- `COSIGN_PASSWORD` - Image signing passphrase

**Optional Configs:**
- files/optional-configs/oc-install.env
- files/optional-configs/pip.conf
- files/optional-configs/cosign.key

### Common Issues and Solutions

**Issue:** "No module named pip"  
**Solution:** Add `python3-pip [platform:rpm]` to files/bindep.txt

**Issue:** Token errors on test  
**Solution:** Token only needed for build/token targets, not test

**Issue:** Image pull errors  
**Solution:** Test target uses `--pull-policy never` for local images

**Issue:** Missing `which` command  
**Solution:** Use `test -f /path/to/binary` instead (minimal images)

**Issue:** AAP version mismatch  
**Solution:** Ensure EE base image matches deployed AAP version (2.5 vs 2.6)

### Documentation Structure (Diátaxis)

**Tutorials (Learning-Oriented):**
- getting-started.md - First EE build experience
- upgrading-to-v1.2.0.md - AAP 2.5 → 2.6 migration

**How-To Guides (Task-Oriented):**
- 13 guides covering build, test, troubleshoot, oc-mirror, Python indexes, signing, etc.

**Reference (Information-Oriented):**
- Makefile targets, YAML spec, tooling, configs, 9 ADRs, security checklist

**Explanation (Understanding-Oriented):**
- Concepts, technology stack, design decisions, YAML design philosophy

### Known Gaps and TODOs

✅ **RESOLVED in v1.2.0:**
- README PIP_INDEX_URL documentation (now documented)
- Makefile vulnerability scanning (now implemented)
- AAP 2.6 base image migration (now complete)

**Future Enhancements:**
- Multi-architecture builds (arm64 support)
- SLSA provenance attestations
- SBOM (Software Bill of Materials) generation
- Automated CVE monitoring integration

### Dependencies

**Python (files/requirements.txt):**
- pip>=26.1.2
- setuptools>=82.0.1
- ara>=1.7.2

**System (files/bindep.txt):**
- python3-pip, git, rsync, jq, tar, curl, dnf

**Collections (files/requirements.yml):**
- 8 collections with specific versions pinned

**Development (requirements-dev.txt):**
- ansible-builder, ansible-navigator, yamllint

### CI/CD Pipeline

**Workflows:**
- build-and-push.yml - Build, test, scan, sign, publish
- docs.yml - Documentation build and deployment
- yamllint.yml - YAML validation
- validate-workflows.yml - GitHub Actions validation

**Triggers:**
- Push to main branch
- Tags (v*, release-*)
- workflow_dispatch (manual)

**Steps:**
1. Checkout code
2. Set up Python 3.11
3. Install tooling (podman, ansible-builder)
4. Login to registries
5. Build image
6. Test (36 tasks)
7. Verify AAP 2.6 base
8. Verify oc-mirror binary
9. Scan (Trivy locally)
10. Publish to Quay
11. Scan (Quay.io)
12. Sign (cosign, releases only)

### Image Tags

**Quay.io Repository:** quay.io/takinosh/ocp4-aap-execution-environment

**Available Tags:**
- `:latest` - Most recent release (v1.2.0, AAP 2.6)
- `:v1.2.0` - AAP 2.6, oc-mirror, security hardening
- `:v1.1.0` - AAP 2.5, OpenShift 4.21, ADRs
- `:v1.0.0` - AAP 2.5, OpenShift 4.19, baseline
- `:v26` - Legacy AAP 2.6 tag (superseded by v1.2.0)
- `:v25` - Legacy AAP 2.5 tag (deprecated)

### Use Cases

**Downstream CI/CD Integration:**
- **Primary Use Case:** ocp4-disconnected-helper project ([Issue #37](https://github.com/tosin2013/ocp4-disconnected-helper/issues/37))
- Validate AAP playbooks in GitHub Actions without storing Automation Hub credentials
- Pre-built image eliminates pip install + collection download time
- Consistent environment between CI and AAP runtime
- Supports ansible.controller and ansible.hub playbook validation

**Disconnected Environments:**
- oc-mirror binary for OpenShift content mirroring
- Custom Python package indexes via PIP_INDEX_URL
- Air-gapped installation guides

**Enterprise Security:**
- Vulnerability scanning (Quay + Trivy)
- Image signing (cosign)
- Supply chain security

**Multi-Cloud Automation:**
- AWS (amazon.aws collection)
- Azure (azure.azcollection)
- OpenShift/Kubernetes (kubernetes.core)

**AAP Platform Integration:**
- ansible.controller for job templates
- ansible.hub for content management
- ansible.platform for infrastructure

## Diátaxis Compass Application

### Study vs Work
- **Study (Tutorials, Explanation):** 2 tutorials, 4 explanation docs
- **Work (How-To, Reference):** 13 how-to guides, 14 reference docs

### Practical vs Theoretical
- **Practical (Tutorials, How-To):** 2 tutorials, 13 how-to guides
- **Theoretical (Reference, Explanation):** 14 reference docs, 4 explanation docs

### Acquisition vs Application
- **Acquisition (Tutorials):** 2 learning-oriented tutorials
- **Application (How-To):** 13 task-oriented guides
- **Information (Reference):** 14 neutral fact sources
- **Understanding (Explanation):** 4 context-building docs

## Conclusion

**Total Documentation:** 40 markdown files organized in Diátaxis framework  
**Total Knowledge Items:** 200+ facts, procedures, decisions cataloged  
**Documentation Completeness:** High - All 4 Diátaxis quadrants well-represented  
**PMB Sync Status:** Ready for memory creation  
**Next Steps:** Create PMB doc memories with DIDs and abstracts
