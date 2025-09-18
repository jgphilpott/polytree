# Testing Guidelines

These notes define conventions and coverage expectations for the test suite.

## Framework

- Use Jest (already configured).
- CoffeeScript test sources compile before Jest run.

## File / Naming

- Name pattern: `*.test.coffee`.
- One logical unit per file (e.g. `triangle.test.coffee`).
 - All helpers from `triangle.coffee` share a single consolidated test file `triangle.test.coffee` (append new helper tests at bottom, do not create a separate file).

## Structure

- Use a small helper factory for repetitive data construction (e.g. `tri()`).
- Keep assertion helpers local (no global shared unless reused across 3+ files).
- Avoid hidden magic numbers; define `EPS`, `TOL`, etc. at top of file.
- Place any new shared helper functions (e.g. geometry builders, orientation wrappers) near the TOP of the consolidated test file so subsequent describe blocks can reuse them.
- Formatting / Whitespace: Insert a blank line immediately after each `describe` declaration line and after each `it` line (before the body) to maintain generous vertical whitespace consistent with CoffeeScript style.

## Assertions

- Prefer strict boolean expectations for intersection routines.
- When additional metadata (e.g. `additions.source/target`) exists:
  - Assert only when meaningful (non‑degenerate segment).
  - Skip segment length assertion for point/degenerate intersections.

## Coverage Expectations (Geometry)

Triangle intersection tests must include:

1. Separated (parallel planes).
2. Separated (skew planes).
3. Proper segment intersection (non‑coplanar).
4. Shared edge (coplanar).
5. Shared vertex only.
6. Vertex pierce (degenerate / vertical fan).
7. Coplanar separated (no overlap).
8. Coplanar partial overlap.
9. Coplanar full containment.
10. Near‑coplanar (epsilon offsets).
11. Degenerate triangle vs valid (no intersection).
12. Degenerate point inside other (count as intersect).
13. Skew oblique intersect.
14. Skew oblique disjoint.
15. Identical triangles (full overlap).
16. Degenerate line across interior.

Future (add later):

- Random fuzz (deterministic seed).
- Stress test large coordinate magnitudes.
- Negative coordinates symmetry cases.
- Performance smoke (N random triangle pairs under threshold).
- Benchmark optional (behind env flag).

## Floating Point

- Use tolerance constant (default `1e-6`) for segment length > 0 checks.
- Do not equality‑compare raw floats except against `0` with documented intent.
- For near‑coplanar classification tests, accept either coplanar true/false if within epsilon band (mark with comment).

## Degenerates

- Explicitly test zero‑area (all points identical).
- Document expectation (intersect only if point lies in other triangle region).

## DRY Principles

- Shared helper naming: `tri()`, `assertIntersection()`.
- Keep helpers minimal; do not abstract prematurely.
- If helper exceeds ~30 LOC or becomes multi‑purpose, split.

## Test Output Clarity

- Include label in thrown error messages for quick identification.
- Avoid console logging in passing tests.
- Use comments to justify non‑obvious expectations (especially degenerate cases).

## Adding New Geometry Tests

When adding a geometry routine (e.g. ray-triangle, octree CSG steps):

1. List edge cases first (comment header).
2. Implement helpers.
3. Write “happy path” test, then edge cases, then degenerates.
4. Add at least one regression test for each bug fixed.

## Performance / Stability

- Long‑running randomized suites should be opt‑in via `process.env.LONG_TESTS`.
- Default `npm test` must remain fast (< 2–3s typical).

## Lint / Style

- Follow CoffeeScript whitespace guidance (blank line after blocks).
- Keep tests readable over condensed.

## TODO Tags

- Allowed only with issue reference: `# TODO(#123): expand fuzz coverage`.
