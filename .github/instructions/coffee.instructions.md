---
applyTo: '*.coffee'
---

# CoffeeScript Contribution Instructions

These guidelines apply to all CoffeeScript source edits in this repository.

## Code Style: Whitespace and Vertical Spacing

- Preserve and prefer generous vertical whitespace for readability.
- Insert a blank line after the following situations:
  - function declarations/definitions
  - if/else blocks
  - loops
  - any change in indentation level
- Do not collapse existing blank lines when editing.

If you are unsure, prefer the more spacious option to maintain consistency with the existing style.

## Reserved Word Note (Project Convention)

CoffeeScript reserves certain identifiers (e.g. `by` used in loop syntax). When needing coordinate component variables that might conflict, prefer capitalized suffix forms:

- Use `aX, aY, aZ` / `bX, bY, bZ` instead of `ax, ay, az` / `bx, by, bz` when there is risk of `by` being parsed as the keyword.
- This avoids accidental parse errors in inline multi-assignment statements.

Adopt this naming in new geometry or test code when generating random coordinates.
