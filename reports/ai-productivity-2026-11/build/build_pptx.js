// Case-study deck.  NODE_PATH=<node_modules> node build_pptx.js <out.pptx> <apply_theme.js>
const fs = require("fs");
const path = require("path");
const pptxgen = require("pptxgenjs");
const React = require("react");
const ReactDOMServer = require("react-dom/server");
const sharp = require("sharp");
const fa = require("react-icons/fa");

const [, , OUT, THEME_JS] = process.argv;
const { applyTheme } = require(THEME_JS);
const R = JSON.parse(fs.readFileSync(path.join(__dirname, "data", "register.json"), "utf8"));
const S = R.summary;
const J = R.rows.find((o) => o.folder === "ovl/zfi_jib_status");
const h = (x) => Math.round(x).toLocaleString("en-US");
const pc = (x) => `${Math.round(x * 100)}%`;
const md = (x) => Math.round(x / 8).toLocaleString("en-US");
const USAGE = JSON.parse(fs.readFileSync(path.join(__dirname, "data", "usage.json"), "utf8"));
const MET = Object.fromEntries(USAGE.metrics.map((m) => [m[0], m[1]]));
const COMMITS = MET["Total commits in the repository, 19/08 - 19/11/26 (all branches)"];
const USAGE_LINES = MET["Lines of ABAP / CDS / script code added in AI commits"].toLocaleString("en-US");

const THEME = {
  name: "Diligent Teal",
  headFontFace: "Cambria",
  bodyFontFace: "Calibri",
  colors: {
    dk1: "1B2A3A", lt1: "FFFFFF", dk2: "0B3C49", lt2: "EEF4F5",
    accent1: "0B5C6B", accent2: "E8A33D", accent3: "5B8C85", accent4: "C8553D", accent5: "8FB8BF", accent6: "5B6B7A",
    hlink: "0B5C6B", folHlink: "5B6B7A",
  },
};
const HEX = THEME.colors;

async function icon(Comp, color, size = 256) {
  const svg = ReactDOMServer.renderToStaticMarkup(React.createElement(Comp, { color: "#" + color, size }));
  const png = await sharp(Buffer.from(svg)).resize(size, size).png().toBuffer();
  return "image/png;base64," + png.toString("base64");
}

(async () => {
  const pres = new pptxgen();
  pres.layout = "LAYOUT_16x9";
  pres.author = "Arnav Johri";
  pres.company = "Diligent Global";
  pres.title = "AI-Enabled SAP ABAP Delivery - JIB Status case study";
  pres.theme = { headFontFace: THEME.headFontFace, bodyFontFace: THEME.bodyFontFace };
  const C = pres.SchemeColor;
  const FOOT = "AI-enabled SAP ABAP delivery  |  ONGC Videsh - JIB Status  |  Method: AI_Use_Case_Register.xlsx";

  pres.defineSlideMaster({
    title: "DARK", background: { color: HEX.dk2 },
    objects: [{ placeholder: { options: { name: "title", type: "title", x: 0.6, y: 1.25, w: 8.8, h: 1.3, fontFace: THEME.headFontFace, fontSize: 36, bold: true, color: C.background1, valign: "top", align: "left", margin: 0 }, text: "" } }],
  });
  pres.defineSlideMaster({
    title: "CLOSING", background: { color: HEX.dk2 },
    objects: [{ placeholder: { options: { name: "title", type: "title", x: 0.6, y: 0.4, w: 8.8, h: 0.75, fontFace: THEME.headFontFace, fontSize: 32, bold: true, color: C.background1, valign: "middle", align: "left", margin: 0 }, text: "" } }],
  });
  pres.defineSlideMaster({
    title: "CONTENT", background: { color: HEX.lt1 },
    margin: [0.5, 0.5, 0.6, 0.5],
    objects: [
      { placeholder: { options: { name: "title", type: "title", x: 0.5, y: 0.28, w: 9.0, h: 0.62, fontFace: THEME.headFontFace, fontSize: 28, bold: true, color: C.text2, valign: "middle", align: "left", margin: 0 }, text: "" } },
      { text: { text: FOOT, options: { x: 0.5, y: 5.22, w: 8.2, h: 0.25, fontSize: 9, color: C.accent6, fontFace: THEME.bodyFontFace, margin: 0 } } },
    ],
    slideNumber: { x: 9.1, y: 5.2, w: 0.4, h: 0.28, fontSize: 9, color: HEX.accent6, fontFace: "Calibri" },
  });

  const ic = {
    db: await icon(fa.FaDatabase, HEX.lt1), sync: await icon(fa.FaSyncAlt, HEX.lt1), check: await icon(fa.FaUserCheck, HEX.lt1),
    code: await icon(fa.FaCode, HEX.lt1), file: await icon(fa.FaFileExcel, HEX.lt1), layer: await icon(fa.FaLayerGroup, HEX.lt1),
    clock: await icon(fa.FaClock, HEX.lt1), shield: await icon(fa.FaShieldAlt, HEX.lt1), recycle: await icon(fa.FaRecycle, HEX.lt1),
    chart: await icon(fa.FaChartBar, HEX.lt1), robot: await icon(fa.FaRobot, HEX.lt1), handshake: await icon(fa.FaHandshake, HEX.lt1),
  };
  const badge = (s, img, x, y, d, fillc, name) => {
    s.addShape(pres.shapes.OVAL, { x, y, w: d, h: d, fill: { color: fillc }, line: { color: fillc }, objectName: name + " circle" });
    s.addImage({ data: img, x: x + d * 0.24, y: y + d * 0.24, w: d * 0.52, h: d * 0.52, objectName: name + " icon", altText: name });
  };
  const tb = (s, text, o) => s.addText(text, Object.assign({ isTextBox: true, fontFace: THEME.bodyFontFace, color: C.text1, margin: 0, valign: "top" }, o));
  const card = (s, x, y, w, hh, name) => s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x, y, w, h: hh, rectRadius: 0.08, fill: { color: C.background2 }, line: { color: C.background2 }, objectName: name });

  // 1 ---------------------------------------------------------------- title
  pres.addSection({ title: "Case study" });
  let s = pres.addSlide({ masterName: "DARK", sectionTitle: "Case study" });
  tb(s, "ONGC VIDESH (OVL)  ·  MANAGEMENT DASHBOARD  'JIB STATUS'", { x: 0.6, y: 0.85, w: 8.8, h: 0.35, fontSize: 13, bold: true, color: C.accent2 });
  s.addText("AI-Enabled SAP ABAP Delivery Improvement", { placeholder: "title" });
  tb(s, "Eight CDS views and an analytical cube, built from a requirement workbook and confirmed by the client in 11 working days", { x: 0.6, y: 2.7, w: 5.6, h: 0.9, fontSize: 16, color: C.background1 });
  s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: 6.55, y: 2.55, w: 2.85, h: 1.55, rectRadius: 0.1, fill: { color: C.accent1 }, line: { color: C.accent1 }, objectName: "Key result panel" });
  tb(s, `${h(J.baseline_h)} h  →  ${h(J.actual_h)} h`, { x: 6.7, y: 2.68, w: 2.6, h: 0.6, fontSize: 28, bold: true, color: C.background1, fontFace: THEME.headFontFace });
  tb(s, `${pc(J.red)} less effort\nconventional vs AI-assisted`, { x: 6.7, y: 3.3, w: 2.6, h: 0.7, fontSize: 13, color: C.background1 });
  tb(s, `Portfolio, 20 Jul - 19 Nov 2026:  ${S.n_counted} AI-assisted use cases  ·  ${COMMITS} commits  ·  ${md(S.saved)} man-days saved  ·  ${pc(S.red)} effort reduction`,
    { x: 0.6, y: 4.55, w: 8.8, h: 0.35, fontSize: 12, color: C.accent5 });
  tb(s, "Arnav Johri  |  Associate Consultant, SAP ABAP  |  Diligent Global  |  19 November 2026", { x: 0.6, y: 4.95, w: 8.8, h: 0.3, fontSize: 10, color: C.accent5 });
  s.addNotes(`Key result: ${h(J.baseline_h)} h conventional vs ${h(J.actual_h)} h AI-assisted for ZFI_JIB_STATUS. Evidence: ovl/zfi_jib_status/ISSUES.md #11 (client mail 17/11/26 'working well and meeting expectations'); ${J.commits} commits over ${J.active_days} active days. Portfolio figures from AI_Use_Case_Register.xlsx, Dashboard.`);

  // 2 ------------------------------------------------------------ challenge
  s = pres.addSlide({ masterName: "CONTENT", sectionTitle: "Case study" });
  s.addText("Business requirement and technical challenge", { placeholder: "title" });
  tb(s, "What the business asked for", { x: 0.5, y: 1.08, w: 4.1, h: 0.3, fontSize: 15, bold: true, color: C.accent1 });
  tb(s, [
    { text: "Per joint venture: is the period's JIB posted, and when was it entered", options: { bullet: true, breakLine: true } },
    { text: "Month, quarter and fiscal-year views; Pending where no JIB exists", options: { bullet: true, breakLine: true } },
    { text: "Document numbers with drill-down to the journal entry", options: { bullet: true, breakLine: true } },
    { text: "Consumed as a Fiori Custom Analytical Query on the Management Dashboard", options: { bullet: true } },
  ], { x: 0.5, y: 1.45, w: 4.1, h: 1.9, fontSize: 13, paraSpaceAfter: 6 });
  tb(s, "Conventional approach and bottlenecks", { x: 0.5, y: 3.6, w: 4.1, h: 0.3, fontSize: 15, bold: true, color: C.accent1 });
  tb(s, `SE16N analysis of BKPF / BSEG / JV data, trial-and-error activation on an older S/4 release, and a model rebuild after every client test: ${h(J.baseline_h)} h (about ${Math.round(J.baseline_h / 8)} working days) for an associate consultant.`,
    { x: 0.5, y: 3.95, w: 4.1, h: 1.1, fontSize: 13 });
  const ch = [
    [ic.db, "No venture on the header", "JIB found by document type from a GS01 set; venture read from the line items"],
    [ic.layer, "Reversals and gaps", "Reversed JIBs handled; months without a JIB must still show as Pending"],
    [ic.shield, "Older S/4 release", "Classic CDS constraints; delivered by abapGit ZIP to a system the AI cannot reach"],
    [ic.sync, "A moving target", "13 logged issues and changes, two client test rounds and four additions"],
  ];
  ch.forEach((c, i) => {
    const y = 1.08 + i * 1.02;
    card(s, 5.0, y, 4.5, 0.9, "Challenge card " + (i + 1));
    badge(s, c[0], 5.13, y + 0.17, 0.56, HEX.accent1, c[1]);
    tb(s, c[1], { x: 5.85, y: y + 0.1, w: 3.55, h: 0.3, fontSize: 13, bold: true, color: C.text2 });
    tb(s, c[2], { x: 5.85, y: y + 0.4, w: 3.55, h: 0.48, fontSize: 11 });
  });
  s.addNotes(`Source: ovl/zfi_jib_status/ISSUES.md rows 1-13 and NOTES.md (design notes 03/11/26). Requirement workbook: docs/Management_Dashboard_-_JIB_Status_-_Final.xlsx. Baseline from the rubric: Very High new development = ${h(J.baseline_h)} h.`);

  // 3 ------------------------------------------------------------- workflow
  s = pres.addSlide({ masterName: "CONTENT", sectionTitle: "Case study" });
  s.addText("How AI was leveraged", { placeholder: "title" });
  tb(s, "AI tool: Claude Code (Anthropic), working from the repository; every object reached SAP through Arnav", { x: 0.5, y: 0.98, w: 9, h: 0.3, fontSize: 12, italic: true, color: C.accent6 });
  const steps = [
    [ic.file, "Requirement", "Workbook and production sample documents checked line by line"],
    [ic.robot, "AI design", "Data model: entry, document, period, venture, clearing, aggregates"],
    [ic.code, "AI build", "Eight CDS views and an abapGit ZIP, release constraints applied"],
    [ic.check, "Human validation", "Import, activation, GS03 / SE16N checks; query built with the GR consultant"],
    [ic.sync, "Feedback loop", "Two client test rounds and four additions, each turned around by the AI"],
  ];
  steps.forEach((st, i) => {
    const x = 0.5 + i * 1.84;
    badge(s, st[0], x + 0.5, 1.45, 0.66, i === 3 ? HEX.accent2 : HEX.accent1, st[1]);
    tb(s, `${i + 1}. ${st[1]}`, { x, y: 2.2, w: 1.66, h: 0.3, fontSize: 13, bold: true, color: C.text2, align: "center" });
    tb(s, st[2], { x, y: 2.52, w: 1.66, h: 0.85, fontSize: 11, align: "center" });
    if (i < 4) s.addShape(pres.shapes.RIGHT_ARROW, { x: x + 1.27, y: 1.66, w: 0.38, h: 0.24, fill: { color: C.accent5 }, line: { color: C.accent5 }, objectName: "Arrow " + (i + 1) });
  });
  card(s, 0.5, 3.55, 9.0, 1.5, "Controls panel");
  tb(s, "Human validation and technical controls", { x: 0.7, y: 3.65, w: 8.6, h: 0.3, fontSize: 14, bold: true, color: C.accent1 });
  tb(s, [
    { text: "Document-type set confirmed in GS03 and SE16N before the model was fixed", options: { bullet: true, breakLine: true } },
    { text: "One object at a time: activation errors fed back and fixed in the next version", options: { bullet: true, breakLine: true } },
    { text: "56 release constraints, each recorded from a real activation failure, applied before any code is written", options: { bullet: true, breakLine: true } },
    { text: "No SAP standard object modified; client test data drove every rebuild", options: { bullet: true } },
  ], { x: 0.7, y: 3.98, w: 8.6, h: 1.05, fontSize: 12, paraSpaceAfter: 2 });
  s.addNotes("Workflow per ovl/zfi_jib_status/ISSUES.md: model rebuilt 04/11 (entry-date) and 06/11 (posting period at document grain); additions 17/11 (all ventures, document type, clearing date and document); BU mapping 19/11. Controls: CLAUDE.md and MEMORY.md section 4 (release constraints).");

  // 4 ----------------------------------------------------------- before / after
  s = pres.addSlide({ masterName: "CONTENT", sectionTitle: "Case study" });
  s.addText("Before vs after AI", { placeholder: "title" });
  s.addChart(pres.charts.BAR, [{ name: "Effort (hours)", labels: ["Conventional", "AI-assisted"], values: [J.baseline_h, J.actual_h] }], {
    x: 0.5, y: 1.05, w: 4.6, h: 3.0, barDir: "col", chartColors: [HEX.accent6, HEX.accent1], showValue: true, dataLabelPosition: "outEnd",
    dataLabelFontSize: 12, dataLabelColor: HEX.dk1, dataLabelFontFace: "+mn-lt", showTitle: true, title: "Total effort (hours)", titleFontSize: 13,
    titleColor: HEX.dk2, titleFontFace: "+mn-lt", showLegend: false, catAxisLabelColor: HEX.accent6, valAxisLabelColor: HEX.accent6,
    catAxisLabelFontFace: "+mn-lt", valAxisLabelFontFace: "+mn-lt", catAxisLabelFontSize: 11, valAxisLabelFontSize: 10, valAxisMaxVal: 70,
    valGridLine: { color: "DDE5E8", size: 0.5 }, catGridLine: { style: "none" }, varyColors: true, objectName: "Effort chart",
  });
  const rows = [
    ["", "Conventional", "AI-assisted"],
    ["Total effort", `${h(J.baseline_h)} h`, `${h(J.actual_h)} h`],
    ["First running version", `Build ~${Math.round(J.baseline_h / 8)} working days`, "Next working day (03 -> 04/11)"],
    ["Requirement -> client confirmation", "Build plus test rounds", "11 working days, 2 test rounds"],
    ["Change rounds absorbed", "Each a manual rebuild", "13 logged, 6 rebuilds / fixes"],
  ];
  s.addTable(rows.map((r, i) => r.map((c, j) => ({ text: c, options: { bold: i === 0 || j === 0, color: i === 0 ? HEX.lt1 : HEX.dk1, fill: { color: i === 0 ? HEX.accent1 : (i % 2 ? HEX.lt2 : HEX.lt1) }, fontSize: 11, fontFace: "Calibri", valign: "middle" } }))),
    { x: 5.35, y: 1.15, w: 4.15, colW: [1.55, 1.25, 1.35], rowH: 0.52, border: { type: "solid", pt: 0.5, color: "C9D3D8" }, objectName: "Comparison table" });
  tb(s, "Conventional effort from the work-type baseline; AI-assisted effort includes prompting, review, activation, testing and every client change round.",
    { x: 0.5, y: 4.3, w: 9.0, h: 0.6, fontSize: 11, italic: true, color: C.accent6 });
  s.addNotes(`Effort: ${h(J.baseline_h)} h baseline (rubric, Very High new development) vs ${h(J.actual_h)} h AI-assisted (git session time ${J.session_h} h x allocation factor ${S.uplift}, with the 16 h minimum for a Very High development). Timeline from ISSUES.md: 03/11 requirement, 04/11 first query, 06/11 client test, 12/11 navigation fix, 17/11 confirmation.`);

  // 5 ----------------------------------------------------------- benefits
  s = pres.addSlide({ masterName: "CONTENT", sectionTitle: "Case study" });
  s.addText("Quantified productivity benefits", { placeholder: "title" });
  const stats = [[`${h(J.saved_h)} h`, "effort saved"], [md(J.saved_h), "man-days saved"], [pc(J.red), "effort reduction"], [`${(J.prod + 1).toFixed(1)}x`, "throughput (+" + Math.round(J.prod * 100) + "%)"]];
  stats.forEach((st, i) => {
    const x = 0.5 + i * 2.28;
    card(s, x, 1.1, 2.1, 1.55, "Stat " + (i + 1));
    tb(s, st[0], { x: x + 0.15, y: 1.22, w: 1.8, h: 0.8, fontSize: 36, bold: true, color: C.accent1, fontFace: THEME.headFontFace, align: "center" });
    tb(s, st[1], { x: x + 0.15, y: 2.05, w: 1.8, h: 0.45, fontSize: 13, color: C.text2, align: "center" });
  });
  badge(s, ic.chart, 0.5, 3.0, 0.62, HEX.accent2, "Portfolio");
  tb(s, "Same method across the whole portfolio", { x: 1.3, y: 2.98, w: 8.2, h: 0.32, fontSize: 15, bold: true, color: C.text2 });
  tb(s, [
    { text: `${S.n_counted} completed use cases: ${h(S.saved)} h (${md(S.saved)} man-days) saved, ${pc(S.red)} effort reduction across PAL, ONGC and T&G`, options: { bullet: true, breakLine: true } },
    { text: `${COMMITS} commits in under four months; ${USAGE_LINES} lines of code; three projects in parallel`, options: { bullet: true, breakLine: true } },
    { text: "Timeline benefit reported separately from hours: 11 working days from requirement to client confirmation", options: { bullet: true } },
  ], { x: 1.3, y: 3.35, w: 8.2, h: 1.5, fontSize: 13, paraSpaceAfter: 5 });
  s.addNotes("Formulas: saved = baseline - actual; reduction = saved / baseline; man-days = saved / 8; productivity improvement = baseline / actual - 1. Portfolio totals: AI_Use_Case_Register.xlsx Dashboard; sensitivity: Effort Assumptions section 7.");

  // 6 ----------------------------------------------------------- quality & value
  s = pres.addSlide({ masterName: "CONTENT", sectionTitle: "Case study" });
  s.addText("Delivery quality and customer value", { placeholder: "title" });
  const cols = [
    [ic.shield, "Development quality", ["All twelve periods generated, so missing JIBs show as Pending", "Reversed documents handled; clearing date and document added", "Document-number navigation to the journal entry", "No SAP standard object modified"]],
    [ic.recycle, "Reuse", ["Same CDS-cube pattern used for Bank Revaluation, Treasury bank register and Per-Barrel analysis", "abapGit ZIP delivery path proven on this landscape", "Release constraints recorded once, applied every time"]],
    [ic.handshake, "Customer value", ["Management sees JIB posting status per venture without Excel", "Client confirmed in writing, 17/11/26", "Capacity released for other OVL work", "Effort value = man-days saved x day rate"]],
  ];
  cols.forEach((c, i) => {
    const x = 0.5 + i * 3.05;
    card(s, x, 1.08, 2.85, 3.45, "Value card " + (i + 1));
    badge(s, c[0], x + 0.18, 1.22, 0.6, HEX.accent1, c[1]);
    tb(s, c[1], { x: x + 0.9, y: 1.36, w: 1.85, h: 0.35, fontSize: 15, bold: true, color: C.text2 });
    tb(s, c[2].map((t, k) => ({ text: t, options: { bullet: true, breakLine: k < c[2].length - 1 } })), { x: x + 0.18, y: 2.0, w: 2.55, h: 2.9, fontSize: 12, paraSpaceAfter: 6 });
  });
  s.addNotes("Quality points from ovl/zfi_jib_status/ISSUES.md rows 5, 8, 9, 11, 12. Reuse: ovl/zfi_bank_reval, ovl/zfi_tr_bankacct, ovl/per_barrel_agenda follow the same classic-view / cube / Custom Analytical Query pattern. No billing rate is recorded, so no monetary value is stated.");

  // 7 ----------------------------------------------------------- conclusion
  s = pres.addSlide({ masterName: "CLOSING", sectionTitle: "Case study" });
  s.addText("Conclusion and replication", { placeholder: "title" });
  const blocks = [
    ["Principal achievement", `A client-confirmed management dashboard in 11 working days at ${pc(J.red)} less effort, one of ${S.n_counted} AI-assisted use cases.`],
    ["Lessons learned", "Fresh source and production samples first; one object at a time with activation feedback; record every release constraint; claim only what the system confirms."],
    ["Replicate across PAL · ONGC · T&G", "PAL: finance workflow and upload tiles on the same loop. ONGC: further dashboard cards on the cube pattern. T&G: forecasting and credit-management analytics."],
    ["Next steps", "Roll the AI delivery toolkit out to the team; extend the dashboard pattern; apply the ATC patterns to the next remediation wave; log effort per object."],
  ];
  blocks.forEach((b, i) => {
    const x = 0.6 + (i % 2) * 4.5, y = 1.45 + Math.floor(i / 2) * 1.85;
    tb(s, b[0], { x, y, w: 4.2, h: 0.35, fontSize: 15, bold: true, color: C.accent2 });
    tb(s, b[1], { x, y: y + 0.4, w: 4.2, h: 1.3, fontSize: 13, color: C.background1 });
  });
  s.addNotes("Portfolio figures: AI_Use_Case_Register.xlsx, Dashboard. T&G = Astral Limited / Project UDAY, delivered through KPMG.");

  await pres.writeFile({ fileName: OUT });
  await applyTheme(OUT, THEME);
  console.log("wrote", OUT);
})();
