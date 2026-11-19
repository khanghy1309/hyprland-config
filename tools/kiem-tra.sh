#!/usr/bin/env bash
# Sổ kiểm tra của repo: nhớ những tệp đã được kiểm tra, để lần sau chỉ phải xem lại những tệp đã đổi.
#
#   tools/kiem-tra.sh            liệt kê tệp đã đổi / mới / đã xoá so với lần kiểm tra trước
#   tools/kiem-tra.sh chay       chạy các bước kiểm tra tự động trên những tệp đó
#   tools/kiem-tra.sh chay --tat-ca        … hoặc trên toàn bộ repo
#   tools/kiem-tra.sh chay TỆP...          … hoặc trên đúng các tệp chỉ ra
#   tools/kiem-tra.sh ghi        ghi mốc mới: coi mọi tệp hiện tại là đã kiểm tra
#                                (chỉ chạy sau khi đã xem lại xong và ghi vào docs/KIEM-TRA.md)
#
# Mốc được lưu ở docs/kiem-tra.sha256 (mã sha256 của từng tệp lúc kiểm tra).
# Cách kiểm tra từng loại tệp, kết quả và những giới hạn đã biết: docs/KIEM-TRA.md.
set -uo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT" || exit 1
LEDGER=docs/kiem-tra.sha256
# hai tệp của chính sổ kiểm tra không tính
SKIP_RE='^docs/(kiem-tra\.sha256|KIEM-TRA\.md)$'

if [[ -t 1 ]]; then R=$'\e[31m' G=$'\e[32m' Y=$'\e[33m' B=$'\e[1m' N=$'\e[0m'; else R='' G='' Y='' B='' N=''; fi

# mọi tệp của repo (đã theo dõi + mới chưa bị .gitignore bỏ qua)
files() {
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        git ls-files -z --cached --others --exclude-standard | tr '\0' '\n'
    else
        find . -type f -not -path './.git/*' | sed 's|^\./||'
    fi | grep -Ev "$SKIP_RE" | LC_ALL=C sort -u | while IFS= read -r f; do [[ -f $f ]] && printf '%s\n' "$f"; done
}

# so với mốc: in "đổi<TAB>tệp", "mới<TAB>tệp", "xoá<TAB>tệp"
diff_ledger() {
    local now; now=$(mktemp)
    files | while IFS= read -r f; do sha256sum -- "$f"; done >"$now"
    if [[ ! -f $LEDGER ]]; then
        awk '{ sub(/^[0-9a-f]+  /, ""); print "mới\t" $0 }' "$now"
    else
        awk '
            FNR == NR { if ($0 ~ /^#/) next; h = $1; sub(/^[0-9a-f]+  /, ""); old[$0] = h; next }
            { h = $1; sub(/^[0-9a-f]+  /, ""); seen[$0] = 1
              if (!($0 in old)) print "mới\t" $0; else if (old[$0] != h) print "đổi\t" $0 }
            END { for (f in old) if (!(f in seen)) print "xoá\t" f }
        ' "$LEDGER" "$now" | LC_ALL=C sort -t$'\t' -k2
    fi
    rm -f "$now"
}

cmd_status() {
    local out; out=$(diff_ledger)
    if [[ -f $LEDGER ]]; then
        echo "Mốc kiểm tra trước: $(sed -n 's/^# lúc: //p' "$LEDGER" | head -n1)"
    else
        echo "Chưa có mốc kiểm tra nào (chưa có $LEDGER)."
    fi
    if [[ -z $out ]]; then
        echo "${G}Không có tệp nào đổi từ lần kiểm tra trước. Không cần kiểm tra lại.${N}"
        return 0
    fi
    echo "${B}Cần kiểm tra lại:${N}"
    printf '%s\n' "$out" | while IFS=$'\t' read -r kind f; do
        case $kind in đổi) c=$Y ;; mới) c=$G ;; *) c=$R ;; esac
        printf '  %s%-4s%s %s\n' "$c" "$kind" "$N" "$f"
    done
    # đổi mã shader mà quên dựng lại .qsb thì Quickshell vẫn chạy bản cũ
    printf '%s\n' "$out" | awk -F'\t' '$1 != "xoá" { print $2 }' | grep -E '\.(frag|vert)$' | while IFS= read -r s; do
        printf '%s\n' "$out" | cut -f2 | grep -qxF -- "$s.qsb" \
            || echo "  ${R}!${N} $s đã đổi nhưng $s.qsb chưa đổi: chạy config/quickshell/shaders/build.sh"
    done
    echo
    echo "Chạy '$0 chay' để kiểm tra tự động những tệp này, rồi xem lại bằng mắt theo docs/KIEM-TRA.md."
}

# ── các bước kiểm tra tự động ──
FAIL=0
fail() { FAIL=$((FAIL + 1)); printf '  %sLỖI%s %s\n' "$R" "$N" "$*"; }
ok()   { printf '  %sổn%s  %s\n' "$G" "$N" "$*"; }
skip() { printf '  %sbỏ%s  %s\n' "$Y" "$N" "$*"; }

QSB=$(command -v qsb || ls /usr/lib/qt6/bin/qsb 2>/dev/null || true)
QMLLINT=$(command -v qmllint || command -v qmllint6 || ls /usr/lib/qt6/bin/qmllint 2>/dev/null || true)
LUAC=$(command -v luac || command -v luac5.4 || true)

is_shell() {
    [[ $1 == *.sh ]] && return 0
    head -n1 -- "$1" 2>/dev/null | grep -qE '^#!.*\b(ba|z|da)?sh\b'
}

check_file() {
    local f=$1 out
    case $f in
        *.qsb|*.png|*.jpg|*.jpeg|*.webp|*.gif|*.mp4|*.webm|*.ttf|*.otf|*.woff2) return 0 ;;
    esac
    if is_shell "$f"; then
        if ! out=$(bash -n -- "$f" 2>&1); then fail "$f: bash -n: $out"; return; fi
        if command -v shellcheck >/dev/null; then
            # -x: theo cả tệp được "source"; mức warning trở lên là phải sửa
            if out=$(shellcheck -x -S warning -- "$f" 2>&1); then ok "$f (bash -n, shellcheck)"
            else fail "$f: shellcheck:"; printf '%s\n' "$out" | sed 's/^/      /'; fi
        else ok "$f (bash -n; không có shellcheck)"; fi
        return
    fi
    case $f in
        *.lua)
            if [[ -z $LUAC ]]; then skip "$f (không có luac)"; return; fi
            if out=$("$LUAC" -p -- "$f" 2>&1); then ok "$f (luac -p)"; else fail "$f: $out"; fi ;;
        *.frag|*.vert)
            if [[ -z $QSB ]]; then skip "$f (không có qsb, cài qt6-shadertools)"; return; fi
            local tmp; tmp=$(mktemp)
            # qsb của Qt 6.5+ có --qt6; bản cũ hơn thì ghi rõ các đích như build.sh
            if out=$("$QSB" --qt6 -o "$tmp" -- "$f" 2>&1) \
               || out=$("$QSB" --glsl "100 es,120,150" --hlsl 50 --msl 12 -o "$tmp" -- "$f" 2>&1); then
                ok "$f (qsb dịch được)"
            else fail "$f: qsb:"; printf '%s\n' "$out" | sed 's/^/      /'; fi
            rm -f "$tmp" ;;
        *.qml)
            if [[ -z $QMLLINT ]]; then skip "$f (không có qmllint; xem mục QML trong docs/KIEM-TRA.md)"; return; fi
            # Quickshell nạp module lúc chạy nên qmllint không biết kiểu của nó: chỉ coi lỗi cú pháp là lỗi
            if out=$("$QMLLINT" --unqualified disable --import disable --unresolved-type disable -- "$f" 2>&1); then ok "$f (qmllint)"
            else fail "$f: qmllint:"; printf '%s\n' "$out" | sed 's/^/      /'; fi ;;
        *.py)
            if out=$(python3 -I -c 'import ast,sys; ast.parse(open(sys.argv[1]).read(), sys.argv[1])' "$f" 2>&1); then ok "$f (python cú pháp)"
            else fail "$f: $out"; fi ;;
        *.js)
            # tệp .js của QML có dòng ".pragma library" / ".import": bỏ đi rồi để node kiểm cú pháp
            if ! command -v node >/dev/null; then skip "$f (không có node)"; return; fi
            local tmpjs; tmpjs=$(mktemp --suffix=.js)
            sed -E 's/^[[:space:]]*\.(pragma|import)[[:space:]].*$//' -- "$f" >"$tmpjs"
            if out=$(node --check "$tmpjs" 2>&1); then ok "$f (node --check)"; else fail "$f: $out"; fi
            rm -f "$tmpjs" ;;
        *.json)
            if out=$(python3 -I -m json.tool -- "$f" 2>&1 >/dev/null); then ok "$f (json)"; else fail "$f: $out"; fi ;;
        *.desktop)
            # metadata.desktop của SDDM không phải tệp .desktop thật (nhóm [SddmGreeterTheme])
            if ! grep -q '^\[Desktop Entry\]' -- "$f"; then skip "$f (không phải Desktop Entry)"
            elif command -v desktop-file-validate >/dev/null; then
                if out=$(desktop-file-validate -- "$f" 2>&1); then ok "$f (desktop-file-validate)"; else fail "$f: $out"; fi
            else skip "$f (không có desktop-file-validate)"; fi ;;
        *)
            # tệp còn lại (css, conf, qss, md, svg...): không có công cụ kiểm tra chung, chỉ báo để xem bằng mắt
            skip "$f (xem bằng mắt)" ;;
    esac
}

cmd_check() {
    local list=()
    if [[ ${1:-} == --tat-ca || ${1:-} == --all ]]; then
        mapfile -t list < <(files)
    elif (($#)); then
        list=("$@")
    else
        mapfile -t list < <(diff_ledger | awk -F'\t' '$1 != "xoá" { print $2 }')
    fi
    if ((${#list[@]} == 0)); then echo "${G}Không có tệp nào cần kiểm tra.${N}"; return 0; fi
    echo "${B}Kiểm tra tự động ${#list[@]} tệp${N}"
    local f
    for f in "${list[@]}"; do
        [[ -f $f ]] || { fail "$f: không có tệp này"; continue; }
        check_file "$f"
    done
    echo
    if ((FAIL)); then echo "${R}$FAIL lỗi.${N}"; return 1; fi
    echo "${G}Không có lỗi tự động.${N} Còn phần xem bằng mắt / chạy thử: docs/KIEM-TRA.md."
}

cmd_record() {
    mkdir -p "$(dirname "$LEDGER")"
    local tmp; tmp=$(mktemp)
    {
        echo "# Mốc kiểm tra của repo (tools/kiem-tra.sh ghi). Không sửa tay."
        echo "# lúc: $(date '+%Y-%m-%d %H:%M %z')"
        if git rev-parse HEAD >/dev/null 2>&1; then echo "# commit gốc: $(git rev-parse --short HEAD)"; fi
        files | while IFS= read -r f; do sha256sum -- "$f"; done
    } >"$tmp"
    mv "$tmp" "$LEDGER"
    echo "Đã ghi mốc cho $(grep -vc '^#' "$LEDGER") tệp vào $LEDGER."
    echo "Nhớ ghi lại những gì đã xem trong docs/KIEM-TRA.md và commit cả hai tệp."
}

case ${1:-} in
    ""|doi|status) cmd_status ;;
    chay|check)    shift; cmd_check "$@" ;;
    ghi|record)    cmd_record ;;
    -h|--help|help) sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//' ;;
    *) echo "Không hiểu '$1'. Xem: $0 --help" >&2; exit 2 ;;
esac
