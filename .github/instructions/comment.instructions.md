# Comment Instructions

These guidelines define the commenting standards for the Polytree codebase.

## Punctuation Rules

### Periods Required

- **Full sentences must end with periods** - Any comment that forms a complete sentence should end with a period.
- **Multi-word descriptive comments should end with periods** - Comments that describe functionality or provide explanations should end with periods.

Examples:

```coffeescript
# Main constructor for creating Polytree nodes.
# Initializes core properties and sets up polygon array management.
```

### Periods Optional

- **Short one or two word comments** may omit periods for brevity.
- **Simple labels or identifiers** can omit periods.

Examples:

```coffeescript
# Core data
# Level counter
# Cleanup
```

## Parameter Documentation

### Format

Use the `@param` format for documenting method parameters:

```coffeescript
# @param parameterName - Description of the parameter.
# @param box - Optional bounding box for spatial partitioning.
# @param parent - Parent Polytree node (null for root).
```

### Return Values

Document return values using `@return`:

```coffeescript
# @return Three.js mesh with union result.
# @return Boolean indicating success.
```

## Section Headers

### Major Sections

Use clear, descriptive section headers with visual separation:

```coffeescript
# === SECTION NAME ===
# or
# ----- Section Name -----
```

### Subsections

Use consistent formatting for subsections:

```coffeescript
# -- Subsection Name --
```

## Inline Comments

### Purpose

- Explain **why** something is done, not just **what** is being done.
- Clarify complex algorithms or business logic.
- Note important implementation details or constraints.

### Examples

```coffeescript
# Offset small amount to account for regular grid.
# Continue subdivision if polygon count exceeds threshold and max depth not reached.
# Use winding number for more accurate inside/outside determination.
```

## Method Documentation

### Required Elements

Every public method should include:

1. **Purpose** - Brief description of what the method does.
2. **Parameters** - All parameters with descriptions.
3. **Return value** - What the method returns (if applicable).
4. **Usage notes** - Any important usage considerations.

### Example

```coffeescript
# Split this node into 8 octree children based on spatial subdivision.
# This creates an octree by recursively subdividing space until polygon density is acceptable.
# @param level - Current subdivision level.
# @return This Polytree instance for method chaining.
split: (level) ->
```

## Code Organization Comments

### Class Sections

Use consistent section headers to organize class methods:

```coffeescript
# === SMALL HELPERS AND GETTERS/SETTERS ===
# === OBJECT CREATION AND COPYING ===
# === CSG OPERATIONS (INSTANCE METHODS) ===
# === CORE POLYGON OPERATIONS ===
# === TREE CONSTRUCTION AND SPATIAL PARTITIONING ===
# === POLYGON QUERIES AND INTERSECTION TESTING ===
# === COMPLEX CSG OPERATIONS AND STATE MANAGEMENT ===
# === CLEANUP AND DISPOSAL METHODS ===
```

## Algorithm Explanations

### Complex Methods

For complex algorithms, include:

- High-level explanation of the approach
- Step-by-step breakdown for critical sections
- References to algorithms or papers when applicable

### Example

```coffeescript
# Complex CSG intersection handling - splits and classifies polygons.
# This is the core method for polygon classification in boolean operations.
# Algorithm steps:
# 1. Filter polygons that intersect and are undecided
# 2. Split intersecting polygons along plane boundaries
# 3. Classify resulting polygon fragments as inside/outside/coplanar
# 4. Apply state rules based on CSG operation type
```

## Comment Maintenance

### Consistency

- Keep commenting style consistent throughout the codebase.
- Update comments when code changes.
- Remove obsolete or misleading comments.

### Clarity

- Write comments for future developers (including your future self).
- Use clear, simple language.
- Avoid technical jargon unless necessary and well-defined.

### Brevity

- Be concise but complete.
- Avoid redundant comments that simply restate the code.
- Focus on the intent and reasoning behind the code.
