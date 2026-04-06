#!/usr/bin/env sh
set -eu

db_path="${1:-apartment_rental.db}"

sqlite3 "$db_path" < sql/schema.sql
sqlite3 "$db_path" < sql/triggers.sql
sqlite3 "$db_path" < sql/views.sql
sqlite3 "$db_path" < sql/seed.sql

printf 'Initialized database at %s\n' "$db_path"
