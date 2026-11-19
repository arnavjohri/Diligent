// Two static report charts (SVG -> PNG).  NODE_PATH=<node_modules with sharp> node make_charts.js
const fs = require("fs");
const path = require("path");
const sharp = require("sharp");

const D = path.join(__dirname, "data");
const R = JSON.parse(fs.readFileSync(path.join(D, "register.json"), "utf8"));
const U = JSON.parse(fs.readFileSync(path.join(D, "usage.json"), "utf8"));
const OUT = path.join(__dirname, "charts");
fs.mkdirSync(OUT, { recursive: true });

const INK = "#1B2A3A", MUTED = "#5B6B7A", GRID = "#E3E8EB", SURF = "#FFFFFF";
const WITH = "#2a78d6";   // categorical slot 1 (with AI)
const BASE = "#A9B4BB";   // neutral reference (without AI)
const FONT = "Arial, Helvetica, sans-serif";
const fmt = (x) => Math.round(x).toLocaleString("en-US");

function bar(x, y, w, h, fill) {          // 4px rounded top, square base
  const r = Math.min(4, h / 2, w / 2);
  return `<path d="M${x},${y + h} L${x},${y + r} Q${x},${y} ${x + r},${y} L${x + w - r},${y} Q${x + w},${y} ${x + w},${y + r} L${x + w},${y + h} Z" fill="${fill}"/>`;
}

async function save(svg, name) {
  await sharp(Buffer.from(svg)).png().toFile(path.join(OUT, name));
  console.log("chart", name);
}

(async () => {
  // 1. effort by project, without vs with AI
  const projs = ["PAL", "ONGC (OVL)", "Astral (KPMG)", "Common (all projects)"];
  const labels = ["PAL", "ONGC (OVL)", "Astral (KPMG)", "Common tools"];
  const bp = R.summary.by_project;
  const W = 1600, H = 720, L = 110, Rm = 40, T = 120, B = 90;
  const max = Math.ceil(Math.max(...projs.map((p) => bp[p].baseline)) / 100) * 100;
  const pw = (W - L - Rm) / projs.length, bw = 120, gap = 4;
  const y = (v) => T + (H - T - B) * (1 - v / max);
  let svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}"><rect width="${W}" height="${H}" fill="${SURF}"/>`;
  svg += `<text x="${L}" y="48" font-family="${FONT}" font-size="34" font-weight="bold" fill="${INK}">Effort by project - without AI vs with AI (hours)</text>`;
  svg += `<rect x="${L}" y="70" width="22" height="22" rx="3" fill="${BASE}"/><text x="${L + 32}" y="89" font-family="${FONT}" font-size="24" fill="${MUTED}">Without AI</text>`;
  svg += `<rect x="${L + 200}" y="70" width="22" height="22" rx="3" fill="${WITH}"/><text x="${L + 232}" y="89" font-family="${FONT}" font-size="24" fill="${MUTED}">With AI</text>`;
  for (let v = 0; v <= max; v += max / 4) {
    svg += `<line x1="${L}" x2="${W - Rm}" y1="${y(v)}" y2="${y(v)}" stroke="${GRID}" stroke-width="2"/>`;
    svg += `<text x="${L - 14}" y="${y(v) + 8}" text-anchor="end" font-family="${FONT}" font-size="22" fill="${MUTED}">${fmt(v)}</text>`;
  }
  projs.forEach((p, i) => {
    const cx = L + pw * i + pw / 2;
    [[bp[p].baseline, BASE, cx - bw - gap / 2], [bp[p].actual, WITH, cx + gap / 2]].forEach(([v, c, x]) => {
      svg += bar(x, y(v), bw, y(0) - y(v), c);
      svg += `<text x="${x + bw / 2}" y="${y(v) - 12}" text-anchor="middle" font-family="${FONT}" font-size="24" font-weight="bold" fill="${INK}">${fmt(v)}</text>`;
    });
    svg += `<text x="${cx}" y="${H - B + 40}" text-anchor="middle" font-family="${FONT}" font-size="26" fill="${INK}">${labels[i]}</text>`;
    svg += `<text x="${cx}" y="${H - B + 72}" text-anchor="middle" font-family="${FONT}" font-size="22" fill="${MUTED}">${fmt(bp[p].saved)} h saved</text>`;
  });
  svg += `<line x1="${L}" x2="${W - Rm}" y1="${y(0)}" y2="${y(0)}" stroke="${MUTED}" stroke-width="2"/></svg>`;
  await save(svg, "effort_by_project.png");

  // 2. monthly activity: commits on client work, active days annotated
  const m = U.monthly;
  const H2 = 640, max2 = Math.ceil(Math.max(...m.map((r) => r[3])) / 100) * 100;
  const y2 = (v) => T + (H2 - T - B) * (1 - v / max2);
  const pw2 = (W - L - Rm) / m.length, bw2 = 170;
  svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H2}" viewBox="0 0 ${W} ${H2}"><rect width="${W}" height="${H2}" fill="${SURF}"/>`;
  svg += `<text x="${L}" y="48" font-family="${FONT}" font-size="34" font-weight="bold" fill="${INK}">Commits per month</text>`;
  svg += `<text x="${L}" y="88" font-family="${FONT}" font-size="24" fill="${MUTED}">Repository history from 19/08/26; days with AI-assisted commits under each bar</text>`;
  for (let v = 0; v <= max2; v += max2 / 4) {
    svg += `<line x1="${L}" x2="${W - Rm}" y1="${y2(v)}" y2="${y2(v)}" stroke="${GRID}" stroke-width="2"/>`;
    svg += `<text x="${L - 14}" y="${y2(v) + 8}" text-anchor="end" font-family="${FONT}" font-size="22" fill="${MUTED}">${fmt(v)}</text>`;
  }
  m.forEach((r, i) => {
    const cx = L + pw2 * i + pw2 / 2, x = cx - bw2 / 2;
    svg += bar(x, y2(r[3]), bw2, y2(0) - y2(r[3]), WITH);
    svg += `<text x="${cx}" y="${y2(r[3]) - 12}" text-anchor="middle" font-family="${FONT}" font-size="26" font-weight="bold" fill="${INK}">${r[3]}</text>`;
    svg += `<text x="${cx}" y="${H2 - B + 40}" text-anchor="middle" font-family="${FONT}" font-size="26" fill="${INK}">${r[0]}</text>`;
    svg += `<text x="${cx}" y="${H2 - B + 72}" text-anchor="middle" font-family="${FONT}" font-size="22" fill="${MUTED}">${r[2]} active days</text>`;
  });
  svg += `<line x1="${L}" x2="${W - Rm}" y1="${y2(0)}" y2="${y2(0)}" stroke="${MUTED}" stroke-width="2"/></svg>`;
  await save(svg, "monthly_activity.png");
})();
