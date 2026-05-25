# Dependency Update Skill

This skill automates the process of checking for outdated dependencies, evaluating compatibility, and proposing or applying updates to the project's dependency files.

## Overview

The dependency update skill performs the following tasks:

1. **Scan** the project for dependency manifests (`pyproject.toml`, `requirements*.txt`, `setup.cfg`, etc.)
2. **Check** each dependency against the latest available versions on PyPI
3. **Evaluate** compatibility by reviewing changelogs and release notes for breaking changes
4. **Propose** a set of safe updates with a summary of changes
5. **Apply** updates to the relevant files and run the verification skill to confirm nothing is broken

## When to Use

- Scheduled maintenance runs (e.g., weekly dependency audits)
- Before a release to ensure dependencies are up-to-date
- After a security advisory affects a transitive or direct dependency
- When a contributor requests a dependency bump via issue or PR

## Inputs

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `mode` | `string` | No | `check` (default) or `apply`. Use `check` to only report, `apply` to write changes. |
| `packages` | `string[]` | No | Specific package names to update. Defaults to all dependencies. |
| `min_severity` | `string` | No | Minimum severity for security-driven updates: `low`, `medium`, `high`, `critical`. |
| `allow_major` | `boolean` | No | Whether to allow major version bumps. Defaults to `false`. |
| `dry_run` | `boolean` | No | If `true`, log proposed changes without writing files. Defaults to `false`. |

## Outputs

- A markdown report listing:
  - Current vs. latest version for each dependency
  - Whether a breaking change was detected
  - Update recommendation (`safe`, `review-needed`, `skip`)
- Updated dependency files (when `mode=apply` and `dry_run=false`)
- A summary comment suitable for posting on a PR or issue

## Workflow

```
Scan manifests
     │
     ▼
Fetch latest versions (PyPI)
     │
     ▼
Filter by policy (major allowed? severity threshold?)
     │
     ▼
Fetch changelogs / release notes
     │
     ▼
Classify each update (safe / review-needed / skip)
     │
     ├─── mode=check ──► Output report only
     │
     └─── mode=apply ──► Patch files ──► Run code-change-verification
```

## Integration with Other Skills

- **code-change-verification**: Automatically invoked after applying updates to confirm tests still pass.
- **pr-review-assist**: The generated report can be attached as a PR review comment.
- **docs-sync**: If a dependency change affects public APIs, docs-sync is triggered to update references.

## Example Usage

```yaml
# Check all dependencies for available updates
skill: dependency-update
params:
  mode: check

# Apply safe minor/patch updates for a specific package
skill: dependency-update
params:
  mode: apply
  packages:
    - httpx
    - pydantic
  allow_major: false
  dry_run: false
```

## Notes

- Major version bumps always require `allow_major: true` and will be flagged as `review-needed` regardless.
- Security updates with severity `high` or `critical` bypass the `allow_major` guard and are always proposed.
- The skill respects version pins and constraints defined in `pyproject.toml` and will not widen constraints without explicit confirmation.
