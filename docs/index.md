# Ansible Execution Environment Documentation

Welcome to the documentation for the Ansible Execution Environment (EE) builder project.

Why this documentation: to give new and advanced users actionable, task-focused guides and the background needed to make sound design decisions with EEs.

## What is an Execution Environment?

In modern automation, a common challenge is ensuring that your Ansible Playbooks run reliably everywhere. An automation might work on your laptop but fail in a CI/CD pipeline because of a different version of Python, a missing library, or an incompatible Ansible Collection.

An **Execution Environment** solves this problem. It is a self-contained container image that packages everything your automation needs to run:

-   A specific version of Ansible
-   Specific versions of Python packages
-   Required Ansible Collections
-   Any necessary system-level libraries or tools

By running your playbooks inside an EE, you guarantee a consistent, predictable, and portable environment for your automation, no matter where it runs.

## Why Use This Project?

While you can build Execution Environments from scratch, this repository provides a framework to make the process standardized, repeatable, and easy to customize.

-   **For New Users:** It provides a "batteries-included" starting point. You can simply edit a few text files to define your dependencies, run `make build`, and get a working EE without needing to be an expert in containerization.
-   **For Advanced Users:** It offers a flexible and powerful way to manage the entire lifecycle of your EEs. The `Makefile` provides hooks to clean, build, test, inspect, and publish your images, and the configuration files offer deep customization options.

This documentation will guide you through understanding, using, and extending this framework.

## ⚡ Quick Reference for New Users

**What's New in v1.2.0:**
- ✨ AAP 2.6 base image support (upgraded from AAP 2.5)
- 🪞 oc-mirror binary for disconnected OpenShift environments
- 📦 Custom Python package index support (PIP_INDEX_URL)
- 🔒 Vulnerability scanning (Quay.io + Trivy)
- ✍️ Image signing with cosign
- ⬆️ Updated dependencies (pip >=26.1.2, setuptools >=82.0.1, GitHub Actions Node.js 24)

See [CHANGELOG.md](../CHANGELOG.md) for complete v1.2.0 release notes.

**First Steps:**
1. Clone the repository
2. Run `make setup` to verify your environment
3. Set `ANSIBLE_HUB_TOKEN` environment variable (for certified collections)
4. Run `make build` to create your execution environment
5. Run `make test` to verify it works
6. (Optional) Run `make scan-local` to check for vulnerabilities

**Key Insights:**
- ✅ `make setup` - Verify environment before building (catches issues early)
- ✅ Python 3.10+ required - Python 3.11 recommended on RHEL 9
- ✅ `python3-pip` must be in `bindep.txt` - Minimal images don't include pip by default
- ✅ Token only needed for `build`/`token` - `test`/`setup`/`lint` work without token
- ✅ Use `--pull-policy never` - Ensures local images are used for testing
- ✅ Minimal images are minimal - Use `test -f` instead of `which` command

**Common Issues:**
- "No module named pip" → Add `python3-pip [platform:rpm]` to `files/bindep.txt`
- Token errors on test → Token check now only runs when needed
- Image pull errors → Test target uses `--pull-policy never`
- Missing `which` command → Use `test -f /path/to/binary` instead

See [Troubleshoot EE Builds](how-to/troubleshoot-ee-builds.md) for detailed solutions.

## 📚 Learning-Oriented: Tutorials

Start here to build your first custom Execution Environment.
- [Getting Started with Execution Environments](tutorials/getting-started.md) - Build your first EE from scratch
- [Upgrading to v1.2.0 (AAP 2.6)](tutorials/upgrading-to-v1.2.0.md) - Step-by-step upgrade from v1.1.0

Who this is for: new users and those upgrading; outcome: a working EE build.

## 🔧 Task-Oriented: How-To Guides

Practical guides for specific tasks and more advanced usage.

**Getting Started:**
- [Build Locally with Makefile and Podman](how-to/build-locally.md)
- [How to Test Your Execution Environment](how-to/testing-execution-environment.md)
- [Troubleshoot EE Builds](how-to/troubleshoot-ee-builds.md)

**New in v1.2.0:**
- [Using oc-mirror in Execution Environments](how-to/use-oc-mirror.md) - Mirror OpenShift content for disconnected environments
- [Using Custom Python Package Indexes](how-to/custom-python-index.md) - Configure PIP_INDEX_URL for custom mirrors
- [Sign and Verify Container Images](how-to/sign-and-verify-images.md) - Image signing with cosign

**Advanced Topics:**
- [Enable Kubernetes and OpenShift Tooling](how-to/enable-kubernetes-openshift.md)
- [How to Add Windows Support](how-to/add-windows-support.md)
- [Advanced Usage Guide](how-to/advanced-usage.md)
- [CI/CD with GitHub Actions and Tekton](how-to/ci-cd.md)
- [Release Process](how-to/release-process.md)

**Developer Guides:**
- [Build Docs Locally (MkDocs)](how-to/build-docs-locally.md)
- [Optional llms.txt Manifest](how-to/llms-txt.md)

Who this is for: practitioners executing tasks; outcome: one concrete result per guide.

## 📖 Information-Oriented: Reference

Detailed technical reference for the tools and configuration.
- [Make Targets and Variables](reference/make-targets.md) - Complete Makefile target reference
- [execution-environment.yml Reference](reference/execution-environment-yaml.md) - YAML specification
- [Tooling Reference](reference/tooling.md) - ansible-builder, ansible-navigator, podman
- [Optional Configs and Secrets](reference/optional-configs-and-secrets.md) - Configuration files
- [Architecture Decision Records (ADRs)](adrs/README.md) - 9 ADRs documenting key decisions
- [VERSION_COMPATIBILITY.md](../VERSION_COMPATIBILITY.md) - AAP 2.5/2.6 compatibility and upgrade paths
- [SECURITY_CHECKLIST.md](SECURITY_CHECKLIST.md) - Security verification checklist

Who this is for: readers needing exact options and commands.

## 💡 Understanding-Oriented: Explanation

Conceptual documentation to understand the underlying architecture and design.
- [Execution Environment Concepts](explanation/concepts.md)
- [Technology Stack](explanation/technology-stack.md)
- [Design Decisions](explanation/design-decisions.md)
- [Why Keep execution-environment.yml Minimal](explanation/execution-environment-yaml-design.md)
Who this is for: decision-makers and maintainers; outcome: understand trade-offs and rationale.
