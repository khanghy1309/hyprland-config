// node render.js <w> <h> <out.png> [t]
const { chromium } = require('playwright');
(async () => {
  const [w, h, out, t] = process.argv.slice(2);
  const b = await chromium.launch();
  const p = await b.newPage({ viewport: { width: +w, height: +h }, deviceScaleFactor: 1 });
  await p.goto('file://' + __dirname + '/scene.html?w=' + w + '&h=' + h);
  if (t) await p.evaluate(tt => draw(tt), +t);
  await p.screenshot({ path: out });
  await b.close();
})();
