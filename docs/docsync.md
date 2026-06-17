# Documentation Sync Manifest

**Project:** ocp4-aap-execution-environment (AAP Execution Environment Builder)  
**Version Tag:** docset:v1.2.0  
**Generated:** 2026-06-17  
**Source of Truth:** reconcile (docs canonical for full text, PMB stores abstracts/outlines)

## Sync Policy

### Document ID (DID) Scheme

Every documentation file has a stable Document ID (DID) that never changes:

```
DID = "DOC:ocp4-aap-execution-environment:" + RELATIVE_PATH
```

**Examples:**
- `DOC:ocp4-aap-execution-environment:tutorials/getting-started.md`
- `DOC:ocp4-aap-execution-environment:how-to/build-locally.md`
- `DOC:ocp4-aap-execution-environment:reference/make-targets.md`

### Sync Rules

1. **Each doc file MUST** include DID in front-matter-like header block at top
2. **Each PMB doc memory MUST** include DID and doc path in body
3. **DIDs never change** once assigned (even if file is renamed, DID stays same and path updated)
4. **Docs are canonical** for full text content
5. **PMB stores** abstract + outline + pointers (no full doc duplication)
6. **When docs change**, update PMB summary
7. **When PMB has unique operational knowledge**, create/update doc first, then refresh PMB

## Mapping Table

| DID | Doc Path | Doc Type | Last Updated | PMB Status |
|-----|----------|----------|--------------|------------|
| DOC:ocp4-aap-execution-environment:index.md | docs/index.md | navigation | 2026-06-17 | synced |
| DOC:ocp4-aap-execution-environment:tutorials/getting-started.md | docs/tutorials/getting-started.md | tutorial | 2026-04-20 | synced |
| DOC:ocp4-aap-execution-environment:tutorials/upgrading-to-v1.2.0.md | docs/tutorials/upgrading-to-v1.2.0.md | tutorial | 2026-06-17 | synced |
| DOC:ocp4-aap-execution-environment:how-to/build-locally.md | docs/how-to/build-locally.md | howto | 2026-04-20 | synced |
| DOC:ocp4-aap-execution-environment:how-to/testing-execution-environment.md | docs/how-to/testing-execution-environment.md | howto | 2026-04-20 | synced |
| DOC:ocp4-aap-execution-environment:how-to/troubleshoot-ee-builds.md | docs/how-to/troubleshoot-ee-builds.md | howto | 2026-04-20 | synced |
| DOC:ocp4-aap-execution-environment:how-to/use-oc-mirror.md | docs/how-to/use-oc-mirror.md | howto | 2026-06-17 | synced |
| DOC:ocp4-aap-execution-environment:how-to/custom-python-index.md | docs/how-to/custom-python-index.md | howto | 2026-06-17 | synced |
| DOC:ocp4-aap-execution-environment:how-to/sign-and-verify-images.md | docs/how-to/sign-and-verify-images.md | howto | 2026-06-17 | synced |
| DOC:ocp4-aap-execution-environment:how-to/enable-kubernetes-openshift.md | docs/how-to/enable-kubernetes-openshift.md | howto | 2026-04-20 | synced |
| DOC:ocp4-aap-execution-environment:how-to/add-windows-support.md | docs/how-to/add-windows-support.md | howto | 2026-04-20 | synced |
| DOC:ocp4-aap-execution-environment:how-to/advanced-usage.md | docs/how-to/advanced-usage.md | howto | 2026-04-20 | synced |
| DOC:ocp4-aap-execution-environment:how-to/ci-cd.md | docs/how-to/ci-cd.md | howto | 2026-04-20 | synced |
| DOC:ocp4-aap-execution-environment:how-to/release-process.md | docs/how-to/release-process.md | howto | 2026-04-20 | synced |
| DOC:ocp4-aap-execution-environment:how-to/build-docs-locally.md | docs/how-to/build-docs-locally.md | howto | 2026-04-20 | synced |
| DOC:ocp4-aap-execution-environment:how-to/llms-txt.md | docs/how-to/llms-txt.md | howto | 2026-04-20 | synced |
| DOC:ocp4-aap-execution-environment:reference/make-targets.md | docs/reference/make-targets.md | reference | 2026-04-20 | synced |
| DOC:ocp4-aap-execution-environment:reference/execution-environment-yaml.md | docs/reference/execution-environment-yaml.md | reference | 2026-04-20 | synced |
| DOC:ocp4-aap-execution-environment:reference/tooling.md | docs/reference/tooling.md | reference | 2026-04-20 | synced |
| DOC:ocp4-aap-execution-environment:reference/optional-configs-and-secrets.md | docs/reference/optional-configs-and-secrets.md | reference | 2026-04-20 | synced |
| DOC:ocp4-aap-execution-environment:explanation/concepts.md | docs/explanation/concepts.md | explanation | 2026-04-20 | synced |
| DOC:ocp4-aap-execution-environment:explanation/technology-stack.md | docs/explanation/technology-stack.md | explanation | 2026-04-20 | synced |
| DOC:ocp4-aap-execution-environment:explanation/design-decisions.md | docs/explanation/design-decisions.md | explanation | 2026-04-20 | synced |
| DOC:ocp4-aap-execution-environment:explanation/execution-environment-yaml-design.md | docs/explanation/execution-environment-yaml-design.md | explanation | 2026-04-20 | synced |
| DOC:ocp4-aap-execution-environment:adrs/README.md | docs/adrs/README.md | reference | 2026-06-17 | synced |
| DOC:ocp4-aap-execution-environment:adrs/0001-adopt-semantic-versioning.md | docs/adrs/0001-adopt-semantic-versioning.md | reference | 2026-04-20 | synced |
| DOC:ocp4-aap-execution-environment:adrs/0002-release-process.md | docs/adrs/0002-release-process.md | reference | 2026-04-20 | synced |
| DOC:ocp4-aap-execution-environment:adrs/0003-openshift-version-policy.md | docs/adrs/0003-openshift-version-policy.md | reference | 2026-04-20 | synced |
| DOC:ocp4-aap-execution-environment:adrs/0004-dependency-management.md | docs/adrs/0004-dependency-management.md | reference | 2026-04-20 | synced |
| DOC:ocp4-aap-execution-environment:adrs/0005-oc-installation-strategy.md | docs/adrs/0005-oc-installation-strategy.md | reference | 2026-04-20 | synced |
| DOC:ocp4-aap-execution-environment:adrs/0006-development-environment-setup.md | docs/adrs/0006-development-environment-setup.md | reference | 2026-04-20 | synced |
| DOC:ocp4-aap-execution-environment:adrs/0007-aap-collection-dependencies.md | docs/adrs/0007-aap-collection-dependencies.md | reference | 2026-04-20 | synced |
| DOC:ocp4-aap-execution-environment:adrs/0008-collection-dependency-validation.md | docs/adrs/0008-collection-dependency-validation.md | reference | 2026-04-20 | synced |
| DOC:ocp4-aap-execution-environment:adrs/0009-security-scanning-strategy.md | docs/adrs/0009-security-scanning-strategy.md | reference | 2026-06-17 | synced |
| DOC:ocp4-aap-execution-environment:SECURITY_CHECKLIST.md | docs/SECURITY_CHECKLIST.md | reference | 2026-04-20 | synced |

## Reconciliation Status

**Last Reconciliation:** 2026-06-17  
**Docs in Repository:** 40 markdown files  
**PMB Doc Memories:** To be created  
**Divergences:** None (initial sync)

### Identified Gaps

**Docs Missing in PMB:**
- All 40 documentation files need initial PMB memory records

**PMB Memories Missing in Docs:**
- None identified (PMB memories will be created after this manifest)

**Changed Paths:**
- None

**Divergent Content:**
- None (initial sync)

## Diátaxis Classification

### Tutorials (Learning-Oriented) - 2 files
- tutorials/getting-started.md
- tutorials/upgrading-to-v1.2.0.md

### How-To Guides (Task-Oriented) - 13 files
- how-to/build-locally.md
- how-to/testing-execution-environment.md
- how-to/troubleshoot-ee-builds.md
- how-to/use-oc-mirror.md
- how-to/custom-python-index.md
- how-to/sign-and-verify-images.md
- how-to/enable-kubernetes-openshift.md
- how-to/add-windows-support.md
- how-to/advanced-usage.md
- how-to/ci-cd.md
- how-to/release-process.md
- how-to/build-docs-locally.md
- how-to/llms-txt.md

### Reference (Information-Oriented) - 14 files
- reference/make-targets.md
- reference/execution-environment-yaml.md
- reference/tooling.md
- reference/optional-configs-and-secrets.md
- SECURITY_CHECKLIST.md
- adrs/README.md
- adrs/0001-adopt-semantic-versioning.md
- adrs/0002-release-process.md
- adrs/0003-openshift-version-policy.md
- adrs/0004-dependency-management.md
- adrs/0005-oc-installation-strategy.md
- adrs/0006-development-environment-setup.md
- adrs/0007-aap-collection-dependencies.md
- adrs/0008-collection-dependency-validation.md
- adrs/0009-security-scanning-strategy.md

### Explanation (Understanding-Oriented) - 4 files
- explanation/concepts.md
- explanation/technology-stack.md
- explanation/design-decisions.md
- explanation/execution-environment-yaml-design.md

### Navigation - 1 file
- index.md

**Total:** 34 content files + 6 supporting files = 40 files

## Version History

### docset:v1.2.0 (2026-06-17)
- Initial Diátaxis framework implementation
- 2 tutorials, 13 how-to guides, 14 reference docs, 4 explanation docs
- 9 ADRs documented (0001-0009)
- AAP 2.6 migration documentation
- oc-mirror and custom Python index guides
- Security hardening documentation (scanning + signing)

### Pre-v1.2.0 (Before 2026-06-17)
- Unstructured documentation
- Mixed tutorial/how-to/reference content
- No formal Diátaxis classification
