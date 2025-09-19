---
applyTo: '*.coffee'
---

# CoffeeScript Contribution Instructions

These guidelines apply to all CoffeeScript source edits in this repository.

## Code Style: Indentation

- Use 4-space indentation for all code blocks (consistent with `.editorconfig`).
- All indentation must be multiples of 4 spaces (4, 8, 12, 16, etc.).

## Code Style: Whitespace and Vertical Spacing

- Preserve and prefer generous vertical whitespace for readability.
- Insert a blank line after the following situations:
  - function declarations/definitions
  - if/else blocks
  - loops
  - any change in indentation level
  - variable assignments before object creation/manipulation
  - between logical groups within functions
- Do not collapse existing blank lines when editing.
- In helper functions, add blank lines to separate logical groups (geometry creation, mesh setup, return statements).
- Remove trailing whitespace consistently.

If you are unsure, prefer the more spacious option to maintain consistency with the existing style.

## Test Code Style Preferences

- Add blank lines after geometry/material creation and before mesh creation.
- Add blank lines after mesh setup and before return statements.
- Align inline comments consistently using single space before # comment.
- For comments explaining parameters, add period after comment for complete sentences.
- Maintain consistent spacing around assignment operators.
- Prefer single-line variable assignments with proper spacing.

## Reserved Word Note (Project Convention)

CoffeeScript reserves certain identifiers (e.g. `by` used in loop syntax). When needing coordinate component variables that might conflict, prefer capitalized suffix forms:

- Use `aX, aY, aZ` / `bX, bY, bZ` instead of `ax, ay, az` / `bx, by, bz` when there is risk of `by` being parsed as the keyword.
- This avoids accidental parse errors in inline multi-assignment statements.

Adopt this naming in new geometry or test code when generating random coordinates.
