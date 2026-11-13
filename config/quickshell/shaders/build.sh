#!/usr/bin/env bash
# Dựng lại các shader (.qsb) từ mã nguồn. Cần gói qt6-shadertools (có /usr/lib/qt6/bin/qsb).
# install.sh tự chạy file này; sửa shader xong thì chạy lại, Quickshell tự tải lại.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
QSB=/usr/lib/qt6/bin/qsb
[[ -x $QSB ]] || QSB="$(command -v qsb || true)"
[[ -n $QSB ]] || { echo "Không thấy qsb (cài gói qt6-shadertools). Dùng tạm các tệp .qsb có sẵn."; exit 0; }
if "$QSB" --help 2>&1 | grep -q -- '--qt6'; then args=(--qt6); else args=(--glsl "100 es,120,150" --hlsl 50 --msl 12); fi
for f in *.frag *.vert; do
    "$QSB" "${args[@]}" -o "$f.qsb" "$f"
done
echo "Đã dựng lại shader: $(ls *.qsb | tr '\n' ' ')"
