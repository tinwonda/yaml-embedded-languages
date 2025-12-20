# YAML Embedded Languages

A Visual Studio Code extension that provides syntax highlighting for embedded code in YAML files. **Currently supports SQL**, with Python, JavaScript, Bash, and other languages planned for future releases. Perfect for database migrations, Spark/Databricks configurations, ETL pipelines, and any YAML-based configuration that contains embedded code.

## Quick Start

Once installed, SQL highlighting works automatically in `.yaml` and `.yml` files using two methods:

1. Add `#language=sql` comment above any YAML key
2. Use YAML keys that contain "sql", "query", "statement", or "table" (e.g., `sql_query`, `user_sql`, `my_query`)

> **Note:** Currently only SQL is supported. Support for Python, JavaScript, Bash, and other languages is planned for future releases.

```yaml
# Method 1: Comment marker
#language=sql
analytics_query: |
  SELECT user_id, COUNT(*) as order_count
  FROM orders
  WHERE status = 'completed'
  GROUP BY user_id

# Method 2: Automatic key pattern detection
sql_query: "SELECT * FROM users WHERE active = true"
```

## Features

### Method 1: Comment Markers (Explicit)

Use comment annotations to explicitly mark SQL code, regardless of the key name. This gives you full control over which values should be highlighted as SQL.

**Supported comment formats:**
- `#language=sql`
- `# language=sql`
- `#lang=sql`
- `# lang=sql`

**Example:**

```yaml
spark_job_timeout_mins: 45
#language=sql
sql_query: |
  WITH date_vars AS (
    SELECT
      date_format(add_months(to_date('{{ ds }}'), -1), 'yyyy-MM') as month_formatted
  )
  SELECT
    user_id,
    month AS grant_month,
    category,
    points
  FROM database.table
  WHERE month = date_vars.month_formatted
```

### Method 2: Key Pattern Matching (Automatic)

SQL is automatically highlighted when the YAML key **contains** any of these patterns (case-insensitive):

- Keys ending with **"query"**: `sql_query`, `user_query`, `analytics_query`, `rawQuery`
- Keys ending with **"sql"**: `sql`, `raw_sql`, `user_sql`, `sqlQuery`
- Keys ending with **"statement"**: `sql_statement`, `insert_statement`, `update_statement`
- Keys ending with **"table"**: `create_table`, `alter_table`, `table`

This flexible pattern matching means you don't need to use specific key names - any key following these patterns will automatically get SQL highlighting.

**Examples that will automatically highlight:**

```yaml
# All of these will be highlighted automatically:
user_query: "SELECT * FROM users"
analytics_sql: "SELECT COUNT(*) FROM events"
migration_statement: "CREATE TABLE products (id INT)"
create_table: "CREATE TABLE orders (id INT)"
myCustomQuery: "SELECT * FROM custom"
raw_sql: "UPDATE users SET active = true"
```

### Supported YAML Value Formats

The extension works with all YAML value types:

#### 1. Inline Strings (Quoted)

```yaml
simple_query: "SELECT * FROM users WHERE id = 1"
double_quoted: "SELECT name FROM products"
single_quoted: 'SELECT * FROM orders'
```

#### 2. Block Scalars - Literal Style (`|`)

Preserves line breaks and indentation - perfect for formatted SQL:

```yaml
sql_query: |
  SELECT
    u.id,
    u.name,
    u.email,
    COUNT(o.id) as order_count
  FROM users u
  LEFT JOIN orders o ON u.id = o.user_id
  WHERE u.active = true
  GROUP BY u.id, u.name, u.email
  ORDER BY order_count DESC
```

#### 3. Block Scalars - Folded Style (`>`)

Folds newlines into spaces:

```yaml
sql: >
  SELECT * FROM posts
  WHERE status = 'published'
  AND author_id = 123
  ORDER BY created_at DESC
```

## Common Use Cases

### Database Migrations

```yaml
database:
  migrations:
    001_create_users:
      sql: |
        CREATE TABLE users (
          id SERIAL PRIMARY KEY,
          name VARCHAR(255) NOT NULL,
          email VARCHAR(255) UNIQUE NOT NULL,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );

        CREATE INDEX idx_users_email ON users(email);

    002_create_orders:
      sql_statement: |
        CREATE TABLE orders (
          id SERIAL PRIMARY KEY,
          user_id INT NOT NULL REFERENCES users(id),
          total DECIMAL(10, 2) NOT NULL,
          status VARCHAR(50) DEFAULT 'pending'
        );
```

### Spark/Databricks Job Configurations

```yaml
job_name: user_analytics
spark_config:
  executor_memory: "4g"
  driver_memory: "2g"

#language=sql
sql_query: |
  WITH monthly_stats AS (
    SELECT
      user_id,
      DATE_TRUNC('month', order_date) as month,
      SUM(amount) as total_spent,
      COUNT(*) as order_count
    FROM orders
    WHERE order_date >= '2024-01-01'
    GROUP BY user_id, DATE_TRUNC('month', order_date)
  )
  SELECT
    u.name,
    ms.month,
    ms.total_spent,
    ms.order_count
  FROM users u
  JOIN monthly_stats ms ON u.id = ms.user_id
  ORDER BY ms.month, ms.total_spent DESC
```

### ETL Pipelines

```yaml
etl_pipeline:
  extract:
    source_query: |
      SELECT *
      FROM source_table
      WHERE updated_at > '{{ last_run_timestamp }}'
      ORDER BY updated_at

  transform:
    #language=sql
    transformation: |
      SELECT
        id,
        UPPER(name) as name,
        LOWER(email) as email,
        DATE_TRUNC('day', created_at) as created_date
      FROM {{source}}
      WHERE email IS NOT NULL

  load:
    insert_statement: |
      INSERT INTO target_table (id, name, email, created_date)
      VALUES (?, ?, ?, ?)
      ON CONFLICT (id) DO UPDATE
      SET name = EXCLUDED.name,
          email = EXCLUDED.email
```

### dbt Models Configuration

```yaml
models:
  - name: user_orders_summary
    description: "Summary of user orders"
    sql_query: |
      SELECT
        user_id,
        COUNT(*) as total_orders,
        SUM(amount) as total_spent,
        AVG(amount) as avg_order_value,
        MIN(order_date) as first_order_date,
        MAX(order_date) as last_order_date
      FROM {{ ref('orders') }}
      GROUP BY user_id
```

### Data Quality Checks

```yaml
data_quality:
  checks:
    - name: check_duplicate_emails
      #language=sql
      validation_query: |
        SELECT email, COUNT(*) as count
        FROM users
        GROUP BY email
        HAVING COUNT(*) > 1

    - name: check_orphaned_orders
      sql: |
        SELECT o.id, o.user_id
        FROM orders o
        LEFT JOIN users u ON o.user_id = u.id
        WHERE u.id IS NULL
```

## Installation

### From Visual Studio Code Marketplace

1. Open VSCode
2. Go to Extensions (Ctrl+Shift+X / Cmd+Shift+X)
3. Search for "YAML Embedded Languages"
4. Click Install

### From VSIX Package

1. Download the `.vsix` file
2. Open VSCode
3. Go to Extensions → More Actions (⋯) → Install from VSIX
4. Select the downloaded file

### From Source

1. Clone this repository
2. Run `npm install` to install dependencies
3. Run `npm run compile` to build the extension
4. Run `npm run package` to create a `.vsix` file
5. Install the `.vsix` file in VSCode

## Configuration

Access settings via: **File → Preferences → Settings** (or `Cmd/Ctrl + ,`) and search for "YAML Embedded" or "YAML SQL".

### Available Settings

#### `yamlSqlHighlight.keyPatterns`

An array of key patterns that should trigger SQL highlighting. This setting exists in `package.json` but is not yet dynamically applied (see Known Limitations).

**Default value:**

```json
{
  "yamlSqlHighlight.keyPatterns": [
    "sql_query",
    "sql",
    "query",
    "sql_statement",
    "raw_sql",
    "sqlQuery"
  ]
}
```

> **Note:** Currently, the actual pattern matching is implemented in the grammar file and matches any key ending with "query", "sql", "statement", or "table" (case-insensitive). Future versions will make this configurable.

#### `yamlSqlHighlight.enableCommentMarkers`

Enable or disable `#language=sql` comment markers for SQL detection.

**Default value:**

```json
{
  "yamlSqlHighlight.enableCommentMarkers": true
}
```

**To disable comment markers:**

```json
{
  "yamlSqlHighlight.enableCommentMarkers": false
}
```

> **Note:** Configuration changes require reloading the VSCode window (Cmd+Shift+P / Ctrl+Shift+P → "Developer: Reload Window")

## Troubleshooting

### SQL code is not being highlighted

**Check these common issues:**

1. **File type**: Ensure the file has `.yaml` or `.yml` extension
2. **Key name**: Verify your key contains "sql", "query", "statement", or "table"
3. **Comment placement**: The `#language=sql` comment must be directly above the key
4. **Indentation**: Ensure proper YAML indentation (block scalars must be indented)
5. **VSCode reload**: After installing, reload the window (Cmd+Shift+P → "Developer: Reload Window")

**Example of correct comment placement:**

```yaml
# ✅ CORRECT - Comment directly above key
#language=sql
my_query: "SELECT * FROM users"

# ❌ INCORRECT - Blank line between comment and key
#language=sql

my_query: "SELECT * FROM users"
```

### Verifying syntax highlighting

To inspect which syntax scopes are being applied:

1. Place your cursor on the SQL code
2. Open Command Palette (Cmd+Shift+P / Ctrl+Shift+P)
3. Run **"Developer: Inspect Editor Tokens and Scopes"**
4. Verify the scope chain includes `source.sql`

### Key pattern not matching

If your custom key name isn't being highlighted:

1. **Quick fix**: Add `#language=sql` comment above the key
2. **Check pattern**: Ensure your key ends with "query", "sql", "statement", or "table"

```yaml
# These will work automatically:
my_query: "SELECT ..."        # ✅ ends with "query"
raw_sql: "SELECT ..."         # ✅ ends with "sql"
update_statement: "UPDATE ..." # ✅ ends with "statement"

# These need a comment marker:
#language=sql
data: "SELECT ..."            # ✅ with comment
```

### Configuration changes not taking effect

Configuration changes currently require a VSCode window reload:

1. Make your configuration changes in settings
2. Open Command Palette (Cmd+Shift+P / Ctrl+Shift+P)
3. Run **"Developer: Reload Window"**

## How It Works

This extension uses VSCode's **TextMate Grammar Injection** system:

1. **Pattern Detection**: Regex patterns detect SQL code blocks by:
   - Checking for `#language=sql` comments
   - Matching YAML keys ending with specific patterns (query, sql, statement, table)

2. **Grammar Injection**: When a match is found, VSCode's built-in SQL grammar (`source.sql`) is injected into that region

3. **Dual Highlighting**: YAML syntax remains highlighted for the rest of the file while SQL regions get SQL-specific highlighting

The grammar injection is defined in [syntaxes/yaml-sql-injection.json](syntaxes/yaml-sql-injection.json) using TextMate scope patterns.

## Supported SQL Features

The extension leverages VSCode's built-in SQL grammar, providing highlighting for:

- **Keywords**: SELECT, FROM, WHERE, JOIN, INSERT, UPDATE, DELETE, CREATE, etc.
- **Data types**: INT, VARCHAR, TIMESTAMP, DECIMAL, BOOLEAN, etc.
- **Operators**: =, <, >, <=, >=, <>, AND, OR, NOT, IN, LIKE, BETWEEN
- **String literals**: Single and double quoted strings
- **Numeric literals**: Integers, decimals, scientific notation
- **Comments**: SQL line comments (`--`) and block comments (`/* */`)
- **Functions**: COUNT, SUM, AVG, MAX, MIN, CAST, COALESCE, etc.
- **Advanced constructs**: CTEs (WITH), window functions, subqueries, CASE expressions
- **DDL statements**: CREATE TABLE, ALTER TABLE, DROP TABLE, CREATE INDEX
- **DML statements**: INSERT, UPDATE, DELETE, MERGE

## Known Limitations

1. **Configuration not dynamic**: Changes to `keyPatterns` setting currently require a VSCode window reload to take effect. The actual pattern matching is hardcoded in the grammar file.

2. **Key pattern is static**: The grammar file currently uses a fixed regex pattern for key matching. The `yamlSqlHighlight.keyPatterns` configuration option is defined but not yet dynamically applied.

3. **YAML flow style not supported**: Flow-style collections (`{key: value}`) are not currently supported, only block-style YAML.

4. **No SQL validation**: This extension only provides syntax highlighting, not SQL validation, linting, or IntelliSense/autocomplete.

5. **Limited language support**: Currently only SQL is supported. Python, JavaScript, Bash, and other languages are planned for future releases.

6. **Comment scope**: The `#language=sql` marker affects only the immediately following key-value pair.

## Development

### Building from source

```bash
# Install dependencies
npm install

# Compile TypeScript
npm run compile

# Watch mode for development
npm run watch
```

### Testing

1. Press `F5` to launch the Extension Development Host
2. Open [examples/test.yaml](examples/test.yaml) for comprehensive test cases
3. Verify SQL highlighting appears correctly

### Packaging

```bash
# Create VSIX package
npm run package

# This creates: yaml-sql-highlight-<version>.vsix
```

### Project Structure

```text
.
├── src/
│   └── extension.ts          # Extension activation code
├── syntaxes/
│   └── yaml-sql-injection.json # TextMate grammar definition
├── examples/
│   └── test.yaml             # Comprehensive test cases
├── package.json              # Extension manifest and configuration
└── tsconfig.json             # TypeScript configuration
```

## Roadmap / Future Enhancements

### High Priority
- [ ] **Python support** - Add syntax highlighting for embedded Python code (`#language=python`)
- [ ] **JavaScript support** - Add syntax highlighting for embedded JavaScript/TypeScript
- [ ] **Bash/Shell support** - Add syntax highlighting for embedded shell scripts
- [ ] **Multiple language support** - Support multiple embedded languages in a single YAML file

### Medium Priority
- [ ] Configurable key patterns through VSCode settings (per language)
- [ ] Dynamic grammar regeneration when configuration changes (no reload required)
- [ ] Content-based auto-detection (detect language from code patterns)
- [ ] Support for YAML flow-style syntax

### Low Priority (SQL-specific)
- [ ] SQL validation and linting integration
- [ ] IntelliSense and autocomplete for SQL
- [ ] Dialect-specific SQL highlighting (PostgreSQL, MySQL, Oracle, etc.)
- [ ] Integration with SQL formatting tools

## Contributing

Contributions are welcome! Here's how you can help:

1. **Report bugs**: Open an issue with reproduction steps
2. **Request features**: Describe your use case and desired functionality
3. **Submit pull requests**: Fork the repository and submit PRs
4. **Improve documentation**: Help make this README even better
5. **Share examples**: Contribute test cases to [examples/test.yaml](examples/test.yaml)

Please ensure your code follows the existing style and includes appropriate tests.

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built using [VSCode's Extension API](https://code.visualstudio.com/api)
- Uses VSCode's built-in SQL TextMate grammar for syntax highlighting
- TextMate grammar injection pattern inspired by VSCode's language embedding system

## Support

- **Issues**: [GitHub Issues](https://github.com/your-username/yaml-embedded-languages/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-username/yaml-embedded-languages/discussions)

---

**Enjoy cleaner, more readable YAML configuration files with SQL syntax highlighting!**
