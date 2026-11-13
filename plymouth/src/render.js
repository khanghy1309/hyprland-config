// Dựng ảnh cho theme Plymouth từ anim.html (cần Node + Playwright).
//   node render.js <thư mục ra> [fps]
// Ra: hello-i.png (viết chữ hello), morph-i.png (hello biến thành chữ ký), mỗi khung kèm
// …-glow-i.png (quầng sáng), sig-halo.png, các dòng chữ, ô mật khẩu.
const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

const out = path.resolve(process.argv[2] || '.');
const fps = +(process.argv[3] || 24);
const HELLO_SEC = 1.4, MORPH_SEC = 1.5;
// viết: nhanh ở giữa, chậm ở đầu và cuối như tay viết
const ease = t => t < 0.5 ? 2 * t * t : 1 - Math.pow(-2 * t + 2, 2) / 2;

(async () => {
  fs.mkdirSync(out, { recursive: true });
  const b = await chromium.launch();
  const page = await b.newPage({ viewport: { width: 1200, height: 560 }, deviceScaleFactor: 1 });
  await page.goto('file://' + path.join(__dirname, 'anim.html'));
  const shot = async name => page.screenshot({ path: path.join(out, name), omitBackground: true });

  const nh = Math.round(HELLO_SEC * fps), nm = Math.round(MORPH_SEC * fps);
  for (let i = 0; i < nh; i++) {
    const p = ease((i + 1) / nh);
    for (const layer of ['ink', 'glow']) {
      await page.evaluate(a => write(a[0], a[1]), [p, layer]);
      await shot(layer === 'ink' ? `hello-${i}.png` : `hello-glow-${i}.png`);
    }
  }
  for (let i = 0; i < nm; i++) {
    const t = (i + 1) / nm;          // morph tự có đường cong tốc độ riêng cho từng điểm
    for (const layer of ['ink', 'glow']) {
      await page.evaluate(a => morph(a[0], a[1]), [t, layer]);
      await shot(layer === 'ink' ? `morph-${i}.png` : `morph-glow-${i}.png`);
    }
  }
  await page.evaluate(() => halo());
  await shot('sig-halo.png');

  // các dòng chữ (vẽ sẵn bằng Geist để không phụ thuộc phông trong initramfs)
  const texts = {
    'text-password': 'Nhập mật khẩu để mở khoá ổ đĩa',
    'text-shutdown': 'Đang tắt máy…',
    'text-reboot': 'Đang khởi động lại…'
  };
  for (const [name, t] of Object.entries(texts)) {
    await page.setContent(`<html><body style="margin:0;background:transparent">
      <div id="t" style="display:inline-block;padding:4px 8px;font:500 30px Geist, sans-serif;color:#e9e4f5;letter-spacing:.2px">${t}</div>
      </body></html>`);
    await (await page.$('#t')).screenshot({ path: path.join(out, name + '.png'), omitBackground: true });
  }
  // ô mật khẩu kính và chấm
  await page.setContent(`<html><body style="margin:0;background:transparent">
    <div id="box" style="width:720px;height:96px;border-radius:48px;background:rgba(255,255,255,.08);
      border:2px solid rgba(255,255,255,.24);box-sizing:border-box"></div>
    <div id="dot" style="width:18px;height:18px;border-radius:9px;background:#f4efff;margin-top:10px"></div>
    </body></html>`);
  await (await page.$('#box')).screenshot({ path: path.join(out, 'box.png'), omitBackground: true });
  await (await page.$('#dot')).screenshot({ path: path.join(out, 'dot.png'), omitBackground: true });

  await b.close();
  console.log(`hello ${nh} khung, biến hình ${nm} khung, ${fps} khung/giây`);
})();
