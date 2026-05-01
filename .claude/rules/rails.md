# Rails Practices

Project-agnostic conventions for Ruby on Rails work. Rails-specific patterns that apply across any Rails project.

---

## Migrations

### Generate via `bin/rails generate migration`

Never hand-author migration files. Always generate them:

```sh
bin/rails generate migration AddXxxToYyy
```

**Rationale**: The generator emits a correct timestamp prefix and boilerplate. Hand-authored files risk timestamp collisions, format drift, and missing default scaffolding.

After generation, edit the body to add the actual `change` logic.

### Roll Back Before Editing an Open Migration

When modifying a migration that has already been migrated locally but not yet shipped, **roll back first, then edit, then migrate again**.

```sh
bin/rails db:rollback   # or db:rollback:primary in multi-DB
# edit the migration file
bin/rails db:migrate
```

**Rationale**: If you edit first, the rollback later runs against a schema that no longer matches the in-file definition. The rollback fails partway, leaving a half-rolled-back state that requires manually commenting out the new lines, rolling back, restoring, and re-editing.

For migrations spanning multiple files, use `db:rollback STEP=N` to roll back the right number.

---

## I18n

### Omit `format: :default` for `I18n.l`

When formatting a date or datetime with the default format, do not pass `format: :default`. It is the default and the explicit form is redundant.

```erb
<%# OK: default form %>
<%= I18n.l(date) %>

<%# OK: explicit alternative format %>
<%= I18n.l(datetime, format: :middle) %>

<%# Avoid: redundant %>
<%= I18n.l(date, format: :default) %>
```

For nullable values, use the explicit `if` guard pattern (matches existing codebase conventions):

```erb
<%= I18n.l(value) if value %>
```

**Rationale**: Writing `format: :default` clutters the call site and obscures intent. Reserve `format:` for cases where the format actually differs from the default.
