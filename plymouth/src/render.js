// Dựng ảnh cho theme Plymouth từ anim.html (cần Node + Playwright).
//   node render.js <thư mục ra> [fps]
// Ra: hello-0.png … (viết chữ hello), sig-0.png … (viết chữ ký), sig-glow.png, và các dòng chữ.
const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

const out = path.resolve(process.argv[2] || '.');
const fps = +(process.argv[3] || 24);
const HELLO_SEC = 2.3, SIG_SEC = 1.9;
// chậm ở đầu và cuối nét như tay viết
const ease = t => t < 0.5 ? 2 * t * t : 1 - Math.pow(-2 * t + 2, 2) / 2;

(async () => {
  fs.mkdirSync(out, { recursive: true });
  const b = await chromium.launch();
  const page = await b.newPage({ viewport: { width: 1200, height: 560 }, deviceScaleFactor: 1 });
  await page.goto('file://' + path.join(__dirname, 'anim.html'));
  const shot = async name => page.screenshot({ path: path.join(out, name), omitBackground: true });

  const nh = Math.round(HELLO_SEC * fps), ns = Math.round(SIG_SEC * fps);
  // mỗi khung hai ảnh: nét sắc (…-i.png) và quầng sáng (…-glow-i.png, pack.py thu nhỏ 4 lần)
  const seq = async (kind, n) => {
    for (let i = 0; i <= n; i++) {
      const p = i < n ? ease((i + 1) / n) : 1, tip = i < n;
      await page.evaluate(a => frame(a[0], a[1], a[2], 'ink'), [kind, p, tip]);
      await shot(`${kind}-${i}.png`);
      await page.evaluate(a => frame(a[0], a[1], a[2], 'glow'), [kind, p, tip]);
      await shot(`${kind}-glow-${i}.png`);
    }
  };
  await seq('hello', nh);
  await seq('sig', ns);
  await page.evaluate(() => glowOnly());
  await shot('sig-halo.png');

  // các dòng chữ (vẽ sẵn bằng Geist để không phụ thuộc phông trong initramfs)
  const texts = {
    'text-password': 'Nhập mật khẩu để mở khoá ổ đĩa',
    'text-shutdown': 'Đang tắt máy…',
    'text-reboot': 'Đang khởi động lại…'
  };
  for (const [name, t] of Object.entries(texts)) {
    await page.setContent(`<html><body style="margin:0;background:transparent">
      <div id="t" style="display:inline-block;padding:4px 8px;font:500 30px Geist, sans-serif;color:#efeaff;letter-spacing:.2px">${t}</div>
      </body></html>`);
    const el = await page.$('#t');
    await el.screenshot({ path: path.join(out, name + '.png'), omitBackground: true });
  }
  // ô mật khẩu kính và chấm
  await page.setContent(`<html><body style="margin:0;background:transparent">
    <div id="box" style="width:720px;height:96px;border-radius:48px;background:rgba(255,255,255,.10);
      border:2px solid rgba(255,255,255,.28);box-sizing:border-box"></div>
    <div id="dot" style="width:18px;height:18px;border-radius:9px;background:#f4efff;margin-top:10px"></div>
    </body></html>`);
  await (await page.$('#box')).screenshot({ path: path.join(out, 'box.png'), omitBackground: true });
  await (await page.$('#dot')).screenshot({ path: path.join(out, 'dot.png'), omitBackground: true });

  await b.close();
  fs.writeFileSync(path.join(out, 'frames.txt'), `hello ${nh + 1}\nsig ${ns + 1}\nfps ${fps}\n`);
  console.log(`hello ${nh + 1} khung, chữ ký ${ns + 1} khung, ${fps} khung/giây`);
})();
