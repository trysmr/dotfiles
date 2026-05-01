---
name: test-workflow
description: Use when implementing features, fixing bugs, changing behavior, adding tests, applying TDD, or deciding whether a change is Spike, Stabilize, or Maintain. Trigger on requests involving implementation, bug fixes, behavior changes, tests, TDD, or test quality.
---

# Test Workflow

実装や振る舞い変更の前に、探索と本番化を分けてテスト方針を決める。

## Phase Classification

Before editing code, declare one phase:

- `Spike`: The shape is unknown. Optimize for learning, not shipping. TDD is not required.
- `Stabilize`: The shape is clear and code will be kept. TDD is required for non-trivial logic.
- `Maintain`: Existing behavior is being changed. TDD is required for behavioral changes.

Trivial config edits, typo fixes, comment updates, and simple renames may skip TDD. State the reason briefly.

## Spike Rules

- Mark spike code clearly through branch name, comments, or a scratch directory.
- After the spike, either discard it and re-implement under `Stabilize`, or explicitly transition to `Stabilize`.
- Do not merge spike code without transitioning to `Stabilize` and adding tests.

## TDD Rules

For `Stabilize` and behavior-changing `Maintain` work:

1. Write tests before implementation.
2. Verify the new tests fail for the expected reason.
3. Implement the smallest change that can pass the tests.
4. Iterate between test and implementation until the relevant suite passes.
5. Run the most relevant existing tests and report any gaps.

## Test Quality

- Expected values must be literals. Do not compute expectations using the method under test.
- Prefer direct setup and assertions in each test case over DRY helpers that hide intent.
- Use comments only as section headings, not as repeats of test names.
- Assert meaningful content, not just IDs or presence.
- When adding a public API contract, test that contract directly at the source.

## Domain Hints

| Work type | Recommended approach |
|---|---|
| Library/API behavior verification | Spike first, capture findings, then Stabilize with TDD |
| Data shape or pipeline design | Spike to confirm shape, then lock schema/types with tests |
| UI or visual iteration | Spike-heavy, then use snapshot or approval tests after layout is accepted |
| Prompt or AI output tuning | Spike-heavy, then use golden-sample snapshot tests for regressions |
