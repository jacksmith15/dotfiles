---
paths:
  - "**/tests/**/*.py"
---


# Rules

- Always use `pytest` for Python testing
- Group tests using classes with `staticmethod` for each test
- Follow the naming pattern `TestUnit.should_pass_test` for tests.
- Pytest config should be maintained in `pyproject.toml` - make sure it includes the correct matcher for `should_` prefixes.
- The test classes should be named with prefix `Test`
- The test methods should be named with prefix `should` and be human readable. For example `TestSerializer.should_return_a_string`.
- Test method names SHOULD NOT start with `test_`. They should start with `should_`.
- Keep code DRY by using `pytest.mark.parametrize` for repetitive tests.
- When using `pytest.mark.parametrize`, use `pytest.param` along with descriptive `id` options to make the test identifiable in output
- Use GIVEN WHEN THEN comments to annotate the test content. These comments should include human readable context, for example `# GIVEN a user has been created`, `# WHEN I request details about the user`, `# I should receive a 200 OK response`
- Prefer pytest fixtures over set-up and tear-down methods
- Tests live in a `tests/` directory adjacent to `src/`. In monorepos laid out as namespace packages, each package instead has its own `tests/` adjacent to its `setup.py`, with no `src/` — check the repo's layout before adding a test directory.
