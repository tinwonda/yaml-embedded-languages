# Change Log

All notable changes to the "yaml-sql-highlight" extension will be documented in this file.

## [0.1.9] - 2024-12-20

### Fixed

- **CRITICAL FIX: Comment markers now work with ANY key name**: `# language=sql` comments now properly highlight SQL regardless of the YAML key name
- Moved `contentName: "source.sql"` to the correct nesting level in the comment marker block pattern
- Simplified outer end pattern to `^(?=#)|^(?=[a-zA-Z_][a-zA-Z0-9_-]*[ \\t]*:(?![ \\t]*(\\||>)))`
- Test with `create_ta:` instead of `create_table:` now works correctly

### Technical Details

- The nested pattern that matches `key: |` now has `contentName: "source.sql"` directly on it
- Removed unnecessary deep nesting of patterns that was preventing proper SQL scope application
- Outer comment marker region ends only at: comments or keys without block scalars
- This ensures the nested pattern for block scalars is properly evaluated

## [0.1.8] - 2024-12-20

### Fixed

- **Fixed block scalar bleeding into comments**: SQL highlighting from one block no longer bleeds into subsequent comments
- Simplified end pattern to `^(?=\\S)` which stops at any non-empty line starting with non-whitespace
- Fixed test case 17 (delete_query) bleeding into test case 18's comment section

### Added

- **Added 'table' to key pattern matching**: Now matches keys ending in `table` (e.g., `create_table`, `alter_table`)
- Test case 18 (DDL operations) now works with comment markers and table key names

### Technical Details

- Changed end patterns from complex alternatives to simple `^(?=\\S)` (lookahead for non-whitespace)
- This properly stops at comment lines, new keys, and any content at root indentation level
- Added `[a-zA-Z_]*[Tt]able` to both inline and block key patterns

## [0.1.7] - 2024-12-20

### Fixed

- **Fixed empty line handling in block scalars**: SQL blocks with empty lines now highlight correctly
- Changed end patterns from `^(?![ \\t])` to `^[^ \\t\\r\\n]` to avoid matching empty lines
- Block scalar content pattern now allows empty lines: `^(?![ \\t]+|$)` instead of `^(?![ \\t]+)`
- Test case 9 now works correctly even with blank lines in the SQL query

### Technical Details

- Empty lines (just `^$`) were incorrectly triggering the end of SQL highlighting
- Fixed in all block scalar patterns: key-pattern-block, comment-marker-block, and nested patterns

## [0.1.6] - 2024-12-20

### Changed

- **Expanded key pattern matching**: Now uses flexible regex patterns instead of hardcoded key list
- Matches any key ending in `query`, `sql`, or `statement` (case-insensitive)
- Examples: `complex_query`, `select_query`, `advanced_sql`, `raw_statement`, etc.
- This makes the extension work with more YAML key naming conventions

### Technical Details

- Changed from `(sql_query|sql|query|...)` to `([a-zA-Z_]*[Qq]uery|[a-zA-Z_]*[Ss]ql|[a-zA-Z_]*[Ss]tatement)`
- Pattern now matches test case 9 (`complex_query`)

## [0.1.5] - 2024-12-20

### Fixed

- Fixed block scalar pattern for comment markers (test case 3)
- Simplified indentation matching: now matches any indented line instead of exact indentation backreference
- Block scalar content detection now more reliable

## [0.1.4] - 2024-12-20

### Fixed

- **BREAKING FIX**: Completely rewrote nested patterns for comment markers
- Inline strings: nested pattern now matches full `key: "value"` structure
- Block scalars: nested pattern matches indented content with proper end detection
- Fixed backreference in patterns (using \\2 instead of \\1 for quote matching)
- End pattern for outer region now properly checks for key existence

### Technical Details

- Comment marker creates outer region
- Nested begin/end pattern includes the YAML key in the begin match
- Block scalar content uses indentation capture and backreference for proper end detection
- This ensures SQL scope is only applied to the actual string/block content

## [0.1.3] - 2024-12-20

### Fixed

- Completely rewrote comment marker patterns using proper region-based matching
- Comment marker now creates a region, with nested patterns for SQL content
- Fixed inline string highlighting after comment markers (test case 2)
- Fixed block scalar highlighting after comment markers (test case 3)

### Technical Changes

- Changed from multiline begin patterns (not supported in TextMate) to region-based approach
- Comment patterns now use begin/end regions with nested content patterns
- Block scalars detected by indentation within the comment marker region

## [0.1.2] - 2024-12-20

### Fixed

- Fixed comment marker patterns to correctly match across multiple lines
- Simplified grammar patterns using non-capturing groups and direct multiline matching
- Comment markers now properly trigger SQL highlighting for both inline strings and block scalars (test cases 2 and 3)

## [0.1.1] - 2024-12-20

### Fixed

- Fixed comment marker detection for inline strings (test case 2)
- Improved grammar patterns to better handle multi-line matching
- Comment markers now correctly trigger SQL highlighting for inline quoted strings

### Changed

- Restructured grammar patterns to use nested patterns for better reliability
- Comment marker patterns now work as region matchers rather than single-line patterns

## [0.1.0] - 2024-12-20

### Added
- Initial release
- SQL syntax highlighting in YAML files using comment markers (`#language=sql`)
- SQL syntax highlighting for specific YAML keys (`sql_query`, `sql`, `query`, etc.)
- Support for inline strings and block scalars (literal `|` and folded `>`)
- Support for nested YAML structures at any indentation level
- Configuration option for customizable key patterns
- Comprehensive test file with examples
- Documentation and usage examples

### Features
- TextMate grammar injection for efficient highlighting
- Works with VSCode's built-in SQL and YAML grammars
- No runtime overhead - purely declarative grammar
- Support for multiple comment marker variants
- Handles SQL comments, strings, and all standard SQL syntax

### Known Limitations
- Configuration changes require window reload
- YAML flow-style collections not yet supported
- No SQL validation or IntelliSense (highlighting only)
