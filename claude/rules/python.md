---
paths:
  - "**/*.py"
---


## 1. Module structure

- **Order declarations by importance**: Place the primary/entry function first (e.g., `def main():`), followed by helper functions it calls. This lets readers understand high-level logic before implementation details.

## 2. Imports

- Use absolute imports
- Prefer the style `from package.subpackage import thing` over `import package.subpackage.thing`
- DO NOT alias import names except where it avoids a naming conflict.
- Specifically never refer to `numpy` as `np`, `pandas` as `pd` etc.
- NEVER `import *`
- Group imports as follows: standard library, third-party, local
- Order imports within each group alphabetically. That means `from x import y` imports come after `import y` (we sort on the line, not the import name)

## 3. Naming

- Use `ALL_CAPS` for module-level constants
- Use `snake_case` for variables, attributes and method names
- Use `PascalCase` for class names
- Use descriptive names. Avoid single character or abbreviated names.

## 4. Type annotations

- Use type annotations wherever possible.
- Do not duplicate type annotations into docstrings. If the function signature explains the types, and the function name/argument names explain their purpose, then no `Args` section is necessary in the docstring.

## 5. Strings

- Do not indent multi-line string expressions (except where the indentation is intended, e.g. docstrings)
- Prefer double quotes for strings
- Prefer f-strings for interpolation

## 6. Logging

- Use `loguru` for logging
- Instead of interpolating log messages, provide logging context as keyword arguments, for example `logger.info("Response successful", duration=duration)`

## 7. Exception handling

- Use `raise` to propagate errors. Do not use return types and values to indicate errors.

## 8. General style

- Prefer a functional coding style (not strict)
- Use list and dict comprehensions for transforming data
- Keep functions and classes focused on a single responsibility
- Follow PEP8 for indentation, spacing, and line length
- Use comments judiciously to highlight complex or subtle parts of the code. Avoid redundant comments that simply echo each expression.
- Where functions have many arguments (e.g. more than 4), prefer keyword arguments over positional.

## 9. Standard library

- Prefer `pathlib` over `os` when handling filepaths, and prefer `pathlib.Path` instead of strings to represent filepaths.
- Use `datetime` to represent timestamps (NOT numerics or strings).
- Prefer `typing.NamedTuple` instead of `tuple` for non-homogenous data

## 10. Third-party libraries

- Use `pytest` for writing tests
- Use `loguru` for logging
- Use `pydantic` for validation and for data classes
- Use `pydantic-settings` for parsing environment variables
- Prefer `polars` to `pandas` for processing tabular data (but avoid both when the logic can be easily implemented in plain Python)
- Use `fire` for implementing simple scripts
