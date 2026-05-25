# PR Review Assist Skill

This skill automates pull request review assistance for the openai-agents-python project. It analyzes code changes, checks for common issues, and provides structured feedback.

## Overview

The PR Review Assist skill helps maintainers and contributors by:
- Analyzing diffs for potential bugs, style violations, and anti-patterns
- Checking that tests are included for new functionality
- Verifying documentation is updated alongside code changes
- Summarizing the scope and impact of changes
- Flagging breaking changes or deprecations

## Usage

This skill is triggered automatically on pull request events or can be invoked manually.

### Inputs

| Parameter | Required | Description |
|-----------|----------|-------------|
| `pr_number` | Yes | The pull request number to review |
| `repo` | No | Repository in `owner/repo` format (defaults to current repo) |
| `review_level` | No | `light`, `standard`, or `deep` (default: `standard`) |
| `focus_areas` | No | Comma-separated list: `tests`, `docs`, `security`, `performance` |

### Outputs

- A structured review comment posted to the PR
- A summary report written to `pr-review-report.md`
- Exit code `0` on success, non-zero on failure

## Review Checks

### Always Performed
1. **Diff summary** — high-level description of what changed
2. **Test coverage** — are new functions/classes accompanied by tests?
3. **Type annotations** — are public APIs fully typed?
4. **Docstrings** — do new public symbols have docstrings?

### Standard and Deep
5. **Import hygiene** — no unused imports, correct grouping
6. **Error handling** — exceptions are caught and handled appropriately
7. **Breaking changes** — public API signatures changed without deprecation notice

### Deep Only
8. **Security scan** — checks for hardcoded secrets, unsafe `eval`, etc.
9. **Performance hints** — obvious O(n²) patterns, unnecessary copies
10. **Dependency audit** — new third-party imports are justified

## Configuration

Create a `.agents/skills/pr-review-assist/config.yaml` to customize behavior:

```yaml
review_level: standard
focus_areas:
  - tests
  - docs
ignore_paths:
  - "*.md"
  - "docs/"
post_comment: true
fail_on_missing_tests: false
```

## Agent Integration

See `agents/openai.yaml` for the OpenAI Agents SDK configuration used to power the AI-assisted review steps.
