
# CONTRIBUTING.md

```markdown
# Contributing to eBPF-for-Windows Build Challenges and Spectre Mitigation Report

Welcome! We encourage community involvement to improve the reliability, accuracy, and security of eBPF-for-Windows builds and documentation. This guide details standard issue resolutions, contribution workflow, coding style, documentation practices, and CI requirements.

---

## Issue Resolution Steps

### Clang/LLVM BPF Target Support

- **Verify Clang Version:** Install Clang 18.1.8 for Windows manually to ensure BPF target availability; newer official builds (Clang 19+) lack BPF target by default. Add Clang to your `PATH` and check with:
  ```bash
  clang --version
  clang -target bpf -c test.c -o test.o
