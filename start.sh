#!/bin/sh
set -eu

PORT="${PORT:-8080}"

# Railway provides PORT at runtime. Keep the application bound to that port.
case "$PORT" in
  ''|*[!0-9]*) PORT=8080 ;;
esac

DB_DIR="${XUI_DB_FOLDER:-/etc/x-ui}"
DB_PATH="$DB_DIR/x-ui.db"

mkdir -p "$DB_DIR" /app/bin /var/log/x-ui

export XUI_DB_FOLDER="$DB_DIR"
export XRAY_LOCATION_ASSET="/app/bin"

# The application creates/migrates the database on startup. Seed the two
# Railway-related settings first so the first boot also uses Railway's PORT.
sqlite3 "$DB_PATH" <<SQL
CREATE TABLE IF NOT EXISTS settings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  key TEXT,
  value TEXT
);
DELETE FROM settings WHERE key IN ('webPort', 'subPort');
INSERT INTO settings (key, value) VALUES ('webPort', '$PORT');
INSERT INTO settings (key, value) VALUES ('subPort', '$PORT');
SQL

echo "Starting panel on 0.0.0.0:${PORT}"
echo "Xray assets: ${XRAY_LOCATION_ASSET}"
echo "Database: ${DB_PATH}"

cd /app
exec ./x-ui
