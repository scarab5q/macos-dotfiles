# ============================================================
# POSTGRES (psql → native nushell tables)
# ============================================================
# No plugin needed: psql emits CSV, `from csv` turns it into a real nushell
# table you can pipe / filter / sort. The password comes from 1Password via
# `op read`, cached in PGPASSWORD for the session so Touch ID prompts once.

# Non-secret libpq connection defaults. `psql` (and pgq below) read these.
# Override per-session, e.g. `$env.PGDATABASE = "masref"`.
$env.PGHOST = "localhost"
$env.PGPORT = "5455"
$env.PGUSER = "postgres"
$env.PGDATABASE = "tms"

# Local dev password (the docker postgres is just "postgres"). For a remote/prod
# DB: clear this (`hide-env PGPASSWORD`) and point PG_OP_REF at a real 1Password
# item — pg-auth then fetches it once per session.
$env.PGPASSWORD = "postgres"

# 1Password ref, used only when PGPASSWORD is empty. EDIT to your vault/item/field.
# Find it with: `op item get <item> --format json | get fields`
const PG_OP_REF = "op://Private/arrow-postgres/password"

# Load the password from 1Password into PGPASSWORD if it isn't already set.
def --env pg-auth [] {
    if ($env.PGPASSWORD? | is-empty) {
        $env.PGPASSWORD = (op read $PG_OP_REF | str trim)
    }
}

# Run a SQL query and return a native nushell table.
# SQL is piped to stdin (avoids -c quoting / paren-escaping headaches).
# Columns are type-inferred by default; --raw keeps everything as strings.
def --env pgq [
    query: string   # SQL to run
    --raw           # don't infer column types
] {
    pg-auth
    let out = ($query | psql --csv)
    if $raw { $out | from csv --no-infer } else { $out | from csv }
}

# List user tables (schema + name) as a filterable table.
def --env pg-tables [] {
    pgq "select table_schema, table_name from information_schema.tables where table_schema not in ('pg_catalog', 'information_schema') order by 1, 2"
}

# Raw psql pinned to a database. No args = interactive session; passes through
# any flags (e.g. `tmsql -c "select 1"`). For nushell tables use pgq instead.
def --env --wrapped tmsql [...args] {
    pg-auth
    with-env {PGDATABASE: "tms"} { psql ...$args }
}

def --env --wrapped mvpql [...args] {
    pg-auth
    with-env {PGDATABASE: "masref"} { psql ...$args }
}
