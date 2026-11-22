#!/usr/bin/env bash
set -euo pipefail

# Tentukan direktori absolut tempat skrip ini berada
APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Muat pustaka fungsi bersama
# shellcheck source=lib/common.sh
source "$APP_DIR/lib/common.sh"

VENV_DIR="$APP_DIR/.venv"
PORT="${PORT:-5000}"

log_info "[1/5] Memeriksa prasyarat..."
require_cmd python3
require_cmd curl
port_is_free "$PORT" || die "port $PORT sudah dipakai proses lain"

log_info "[2/5] Menyiapkan virtual environment..."
if [ ! -d "$VENV_DIR" ]; then
    python3 -m venv "$VENV_DIR"
    log_info "Virtual environment berhasil dibuat."
else
    log_info "Virtual environment sudah ada, melewati pembuatan."
fi

log_info "[3/5] Menginstal dependencies..."
source "$VENV_DIR/bin/activate"
if [ -f "$APP_DIR/requirements.txt" ]; then
    pip install -q -r "$APP_DIR/requirements.txt"
    log_info "Dependencies berhasil diinstal."
else
    log_warn "File requirements.txt tidak ditemukan, melewati instalasi."
fi

log_info "[4/5] Menjalankan aplikasi di background..."
nohup python3 "$APP_DIR/src/app.py" > /tmp/app-sentra.out 2>&1 &
APP_PID=$!
log_info "Aplikasi berjalan dengan PID $APP_PID"

log_info "[5/5] Memverifikasi endpoint /health..."
sleep 2
if curl -s "http://127.0.0.1:$PORT/health" > /dev/null; then
    log_info "Aplikasi sehat dan merespons."
else
    log_warn "Aplikasi tidak merespons di port $PORT."
fi
