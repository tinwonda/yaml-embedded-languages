# Bug Fix Summary: YAML Keys Not Highlighted After SQL Blocks

## Problem
When using the `#language=sql` comment marker followed by a SQL block, any YAML keys that came after the SQL block were not being highlighted as YAML keys.

### Example of the bug:
```yaml
#language=sql
sql_query: >
  SELECT
    user_id,
    name
  FROM users
output_dir: s3://bucket/path  # ← This key was NOT highlighted
another_key: value            # ← This key was NOT highlighted
```

## Root Cause
The `sql-comment-marker` pattern in the syntax grammar would activate when `#language=sql` was encountered. This pattern looked for SQL blocks (keys followed by `|`, `>`, or quotes) and would remain active until:
1. Another `#` comment was found, OR
2. An empty line was encountered, OR
3. A YAML key NOT followed by `|`, `>`, or quotes was found

When the SQL block ended (e.g., at `output_dir:`), the nested SQL pattern would end, but the outer `sql-comment-marker` region would still be active. The problem was that keys like `output_dir:` didn't match any of the SQL patterns within the `sql-comment-marker` region, but there was no fallback to the base YAML grammar for highlighting them as regular YAML keys.

## Solution
Added a fallback pattern in the `sql-comment-marker` region that includes the base YAML grammar:

```json
{
  "include": "source.yaml"
}
```

This ensures that any lines within the `#language=sql` region that don't match SQL patterns will still be processed by the base YAML grammar and highlighted correctly.

## Files Changed
- `syntaxes/yaml-sql-injection.json` (line 73-75): Added fallback pattern

## Testing
The fix has been verified to:
1. ✅ Correctly highlight YAML keys after SQL blocks (like `output_dir:`)
2. ✅ Not break existing SQL highlighting in block scalars
3. ✅ Not break existing SQL highlighting in quoted strings
4. ✅ Pass all linting and compilation checks

## Test Cases
Created `test_fix.yaml` with various scenarios:
- SQL blocks followed by YAML keys (without empty lines)
- SQL blocks with both `>` (folded) and `|` (literal) styles
- Multiple SQL blocks in sequence
- Normal YAML content without SQL blocks

## Backward Compatibility
✅ This fix is fully backward compatible. It only affects the highlighting behavior and does not change the syntax parsing. All existing YAML files with SQL blocks will continue to work and will now have better highlighting.
