---
paths:
  - "**/*.{ts,tsx}"
---

# TypeScript

A project's own CLAUDE.md overrides anything here. Where this file states a default, check the repo before applying it.

## Imports

- Use absolute imports when possible (e.g. `@/lib/...`). Check the repo's `tsconfig.json` `paths` for what the alias maps to, and whether it is a monorepo.
- Do not include file extensions in import statements (omit `.ts`, `.tsx`, `.js`, `.jsx`)
- Group imports as follows: standard library, third-party, local
- Order imports within each group alphabetically

## Naming Conventions

- Use `camelCase` for variables, functions, and method names
- Use `PascalCase` for classes, interfaces, types, and components
- Use `UPPER_SNAKE_CASE` for module-level constants
- Use descriptive names. Avoid single character or abbreviated names (except for common loop variables like `i`, `j`, `k`)
- Where there is a default export, file names should match the exported class or function name (e.g., `CheckBox.tsx` exports `CheckBox`)

## Type Definitions

- Use type annotations wherever possible
- Prefer `interface` for object shapes that may be extended
- Prefer `type` for unions, intersections, and computed types
- Use explicit return types for functions, especially public APIs
- Avoid `any` - use `unknown` when the type is truly unknown, then narrow it
- Use type guards and assertion functions for runtime type checking
- Prefer type inference for simple local variables

## Functions and Methods

- Prefer functional programming patterns
- Use function declarations for top-level functions and methods
- Only use arrow functions where necessary for including `this` in closures, or for extremely simple anonymous functions.
- Keep functions focused on a single responsibility
- Prefer destructured object parameters to functions, so that function invocations are more readable without needing to know exact argument ordering
- Use default parameters instead of conditional logic when possible

## React Components

- Use functional components with hooks
- Order within Function Components:
  1. refs
  2. other hook instantiation
  3. state
  4. memos
  5. callbacks
  6. useEffects
- Type component props following the convention already used by the repo's existing components. Where there is none, use a named `interface`.
- Extract complex logic into custom hooks

## Code Style

- Use whichever formatter the repo already configures, and do not introduce a second one. Check for `biome.json`, `.prettierrc`, or an `eslint` config before assuming.
- Keep code DRY - avoid duplication by extracting shared logic
- Prefer simple solutions over complex ones
- Use comments judiciously to highlight complex or subtle parts of the code
- Avoid redundant comments that simply echo the code

## Error Handling

- Use typed error classes when possible
- Prefer throwing errors over returning error values
- Use `try-catch` blocks for error handling, not for control flow
- Always handle promise rejections (use `.catch()` or `try-catch` with `await`)

## Testing

- Include unit tests for all new components and functions
- Match the repo's existing test-file naming rather than mixing conventions. `*.spec.ts` is the default, but projects that run both a unit runner and an e2e runner usually split them (e.g. Vitest `*.test.ts` alongside Playwright `*.spec.ts`) — check before adding a file.
- Test files should either be co-located with source files, or under a co-located `__tests__` directory (when there are many adjacent modules)
- Use descriptive test names that explain what is being tested

## General Best Practices

- Always add a new line to the end of files
- Avoid premature optimization
- When fixing an issue or bug, do not introduce a new pattern or technology without first exhausting all options for the existing implementation
- If you have to add a new pattern or technology, make sure you remove the old code it is replacing
- Check for existing similar code before creating new implementations
