"""Thu gọn khung hình cho Plymouth: cắt sát vùng có nét (cùng một khung cho cả loạt),
giảm còn 256 màu có kênh trong suốt, rồi ghi vị trí vào layout.txt.
Usage: python3 -I pack.py <thư mục khung thô> <thư mục theme>"""
import sys, os, glob, shutil
from PIL import Image

src, dst = sys.argv[1], sys.argv[2]
os.makedirs(dst, exist_ok=True)
W, H = 1200, 560            # khung vẽ gốc (gấp đôi 600×280)
lines = []

def bbox_of(files):
    box = None
    for f in files:
        b = Image.open(f).getchannel("A").point(lambda a: 255 if a > 2 else 0).getbbox()
        if b:
            box = b if box is None else (min(box[0], b[0]), min(box[1], b[1]), max(box[2], b[2]), max(box[3], b[3]))
    return box

GLOW_DOWN = 4               # quầng sáng mờ sẵn, lưu nhỏ 4 lần, Plymouth phóng lại

def save_glow(im, path):
    im.resize((max(1, im.width // GLOW_DOWN), max(1, im.height // GLOW_DOWN)), Image.LANCZOS).save(path, optimize=True)

def save(im, path):
    q = im.quantize(256, method=Image.Quantize.FASTOCTREE)
    q.save(path, optimize=True)

for kind in ("hello", "morph"):
    files = sorted((p for p in glob.glob(f"{src}/{kind}-*.png") if p.rsplit("-", 1)[1][:-4].isdigit() and "-glow-" not in p),
                   key=lambda p: int(p.rsplit("-", 1)[1][:-4]))
    glows = [f.replace(f"/{kind}-", f"/{kind}-glow-") for f in files]
    box = bbox_of(files + glows + ([f"{src}/sig-halo.png"] if kind == "morph" else []))
    # khung chia hết cho GLOW_DOWN để phóng lại khớp từng điểm ảnh
    x0, y0, x1, y1 = box
    x1 = x0 + -(-(x1 - x0) // GLOW_DOWN) * GLOW_DOWN
    y1 = y0 + -(-(y1 - y0) // GLOW_DOWN) * GLOW_DOWN
    box = (x0, y0, x1, y1)
    for f, gf in zip(files, glows):
        save(Image.open(f).crop(box), f"{dst}/{os.path.basename(f)}")
        save_glow(Image.open(gf).crop(box), f"{dst}/{os.path.basename(gf)}")
    if kind == "morph":
        save_glow(Image.open(f"{src}/sig-halo.png").crop(box), f"{dst}/sig-halo.png")
    # độ lệch tâm so với giữa khung gốc, và số khung
    lines.append(f"{kind} {len(files)} {x0 - W // 2} {y0 - H // 2} {x1 - x0} {y1 - y0}")

for f in ("text-password.png", "text-shutdown.png", "text-reboot.png", "box.png", "dot.png"):
    shutil.copy(f"{src}/{f}", f"{dst}/{f}")
open(f"{dst}/layout.txt", "w").write("\n".join(lines) + "\n")
print("\n".join(lines))
