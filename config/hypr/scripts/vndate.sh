#!/usr/bin/env bash
# In ngày bằng tiếng Việt, ví dụ: "Thứ Năm, 12 tháng 11"
# (không phụ thuộc máy đã bật ngôn ngữ vi_VN hay chưa)
days=("Chủ Nhật" "Thứ Hai" "Thứ Ba" "Thứ Tư" "Thứ Năm" "Thứ Sáu" "Thứ Bảy")
printf '%s, %d tháng %d\n' "${days[$(date +%w)]}" "$(date +%-d)" "$(date +%-m)"
