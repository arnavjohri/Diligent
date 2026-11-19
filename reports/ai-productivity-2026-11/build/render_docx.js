// Renders a JSON content description into a .docx (docx-js).
// usage: node render_docx.js content.json out.docx
const fs = require("fs");
const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell, WidthType, ShadingType,
  HeadingLevel, AlignmentType, LevelFormat, PageOrientation, BorderStyle, Footer, Header,
  PageNumber, TableOfContents, VerticalAlign, PageBreak, TableLayoutType, ImageRun,
} = require("docx");

const [, , inPath, outPath] = process.argv;
const doc = JSON.parse(fs.readFileSync(inPath, "utf8"));

const FONT = "Arial";
const INK = "1B2A3A";
const ACCENT = "0B5C6B";
const MUTED = "5B6B7A";
const HEAD_FILL = "0B5C6B";
const ZEBRA = "F1F6F7";
const NOTE_FILL = "EEF4F5";
const RULE = "C9D3D8";

const A4_W = 11906, A4_H = 16838, MARGIN = 1080; // 0.75"
const widthFor = (o) => (o === "landscape" ? A4_H : A4_W) - 2 * MARGIN;

function runs(text, base = {}) {
  // **bold** and `code` inline markup
  const out = [];
  const re = /(\*\*[^*]+\*\*|`[^`]+`)/g;
  String(text).split(re).forEach((part) => {
    if (!part) return;
    if (part.startsWith("**")) out.push(new TextRun({ ...base, text: part.slice(2, -2), bold: true }));
    else if (part.startsWith("`")) out.push(new TextRun({ ...base, text: part.slice(1, -1), font: "Courier New" }));
    else out.push(new TextRun({ ...base, text: part }));
  });
  return out;
}

function para(text, opts = {}) {
  return new Paragraph({
    spacing: { before: opts.before ?? 0, after: opts.after ?? 120, line: opts.line ?? 276 },
    alignment: opts.align,
    keepNext: opts.keepNext,
    children: runs(text, { font: FONT, size: opts.size ?? 20, color: opts.color ?? INK, italics: opts.italics, bold: opts.bold }),
  });
}

function table(b, orientation) {
  const total = widthFor(orientation);
  const rel = b.widths || b.header.map(() => 1);
  const sum = rel.reduce((a, c) => a + c, 0);
  let cols = rel.map((r) => Math.floor((r / sum) * total));
  cols[cols.length - 1] += total - cols.reduce((a, c) => a + c, 0);
  const fs_ = (b.fontSize ?? 8) * 2;
  const border = { style: BorderStyle.SINGLE, size: 4, color: RULE };
  const borders = { top: border, bottom: border, left: border, right: border };
  const cell = (txt, i, o = {}) =>
    new TableCell({
      width: { size: cols[i], type: WidthType.DXA },
      borders,
      verticalAlign: VerticalAlign.TOP,
      shading: o.fill ? { type: ShadingType.CLEAR, color: "auto", fill: o.fill } : undefined,
      margins: { top: 50, bottom: 50, left: 70, right: 70 },
      children: String(txt ?? "").split("\n").map(
        (line) =>
          new Paragraph({
            spacing: { before: 0, after: 20, line: 240 },
            alignment: o.align,
            children: runs(line, { font: FONT, size: fs_, color: o.color ?? INK, bold: o.bold }),
          })
      ),
    });
  const numeric = b.numeric || [];
  const rows = [
    new TableRow({
      tableHeader: true,
      cantSplit: true,
      children: b.header.map((h, i) => cell(h, i, { fill: HEAD_FILL, color: "FFFFFF", bold: true })),
    }),
    ...b.rows.map(
      (r, ri) =>
        new TableRow({
          cantSplit: b.cantSplit ?? false,
          children: r.map((c, i) =>
            cell(c, i, {
              fill: b.totalRow && ri === b.rows.length - 1 ? "DDE9EB" : ri % 2 ? ZEBRA : undefined,
              bold: (b.totalRow && ri === b.rows.length - 1) || (b.boldFirst && i === 0),
              align: numeric.includes(i) ? AlignmentType.RIGHT : undefined,
            })
          ),
        })
    ),
  ];
  return new Table({ width: { size: total, type: WidthType.DXA }, columnWidths: cols, layout: TableLayoutType.FIXED, rows });
}

function kpis(b, orientation) {
  const total = widthFor(orientation);
  const n = b.items.length;
  const w = Math.floor(total / n);
  const cols = b.items.map((_, i) => (i === n - 1 ? total - w * (n - 1) : w));
  const none = { style: BorderStyle.SINGLE, size: 12, color: "FFFFFF" };
  return new Table({
    width: { size: total, type: WidthType.DXA },
    columnWidths: cols,
    layout: TableLayoutType.FIXED,
    rows: [
      new TableRow({
        cantSplit: true,
        children: b.items.map(
          (k, i) =>
            new TableCell({
              width: { size: cols[i], type: WidthType.DXA },
              shading: { type: ShadingType.CLEAR, color: "auto", fill: NOTE_FILL },
              borders: { top: none, bottom: none, left: none, right: none },
              margins: { top: 140, bottom: 140, left: 140, right: 140 },
              children: [
                new Paragraph({ spacing: { after: 40 }, children: [new TextRun({ text: k.value, font: FONT, size: 40, bold: true, color: ACCENT })] }),
                new Paragraph({ spacing: { after: 20 }, children: [new TextRun({ text: k.label, font: FONT, size: 17, bold: true, color: INK })] }),
                new Paragraph({ spacing: { after: 0 }, children: [new TextRun({ text: k.note || "", font: FONT, size: 15, color: MUTED })] }),
              ],
            })
        ),
      }),
    ],
  });
}

function block(b, orientation) {
  switch (b.t) {
    case "h1":
      return [new Paragraph({ heading: HeadingLevel.HEADING_1, pageBreakBefore: b.pageBreak ?? false, children: [new TextRun({ text: b.text })] })];
    case "h2":
      return [new Paragraph({ heading: HeadingLevel.HEADING_2, children: [new TextRun({ text: b.text })] })];
    case "h3":
      return [new Paragraph({ heading: HeadingLevel.HEADING_3, children: [new TextRun({ text: b.text })] })];
    case "p":
      return [para(b.text, b)];
    case "bullets":
      return b.items.map(
        (it) =>
          new Paragraph({
            numbering: { reference: "bul", level: 0 },
            spacing: { before: 0, after: 60, line: 264 },
            children: runs(it, { font: FONT, size: b.size ?? 20, color: INK }),
          })
      );
    case "numbered":
      return b.items.map(
        (it) =>
          new Paragraph({
            numbering: { reference: b.ref || "num", level: 0 },
            spacing: { before: 0, after: 60, line: 264 },
            children: runs(it, { font: FONT, size: b.size ?? 20, color: INK }),
          })
      );
    case "note":
      return [
        new Paragraph({
          spacing: { before: 80, after: 160, line: 264 },
          shading: { type: ShadingType.CLEAR, color: "auto", fill: NOTE_FILL },
          indent: { left: 140, right: 140 },
          children: runs(b.text, { font: FONT, size: 18, color: INK }),
        }),
      ];
    case "table":
      return [
        ...(b.caption ? [para(b.caption, { size: 17, bold: true, color: ACCENT, after: 60, before: 120, keepNext: true })] : []),
        table(b, orientation),
        para(b.source ? b.source : "", { size: 15, color: MUTED, after: 160, before: 40 }),
      ];
    case "kpis":
      return [kpis(b, orientation), para("", { after: 120 })];
    case "toc":
      return [new TableOfContents("Contents", { hyperlink: true, headingStyleRange: "1-2" })];
    case "image":
      return [
        new Paragraph({ spacing: { before: 120, after: 40 }, alignment: AlignmentType.CENTER, keepNext: true,
          children: [new ImageRun({ type: "png", data: fs.readFileSync(b.path), transformation: { width: b.w, height: b.h },
                                    altText: { title: b.alt || "chart", description: b.alt || "chart", name: b.alt || "chart" } })] }),
        para(b.caption || "", { size: 15, color: MUTED, after: 160, align: AlignmentType.CENTER }),
      ];
    case "pagebreak":
      return [new Paragraph({ children: [new PageBreak()] })];
    case "cover":
      return [
        para("", { after: 2400 }),
        new Paragraph({ spacing: { after: 200 }, children: [new TextRun({ text: b.kicker, font: FONT, size: 22, bold: true, color: ACCENT })] }),
        new Paragraph({ spacing: { after: 240, line: 560 }, children: [new TextRun({ text: b.title, font: FONT, size: 52, bold: true, color: INK })] }),
        new Paragraph({ spacing: { after: 600, line: 320 }, children: [new TextRun({ text: b.subtitle, font: FONT, size: 26, color: MUTED })] }),
        ...b.lines.map((l) => new Paragraph({ spacing: { after: 80 }, children: runs(l, { font: FONT, size: 20, color: INK }) })),
      ];
    default:
      throw new Error("unknown block " + b.t);
  }
}

const sections = doc.sections.map((s) => {
  const o = s.orientation || "portrait";
  return {
    properties: {
      page: {
        size: { width: A4_W, height: A4_H, orientation: o === "landscape" ? PageOrientation.LANDSCAPE : PageOrientation.PORTRAIT },
        margin: { top: MARGIN, bottom: MARGIN, left: MARGIN, right: MARGIN },
      },
    },
    headers: s.noHeader
      ? undefined
      : { default: new Header({ children: [new Paragraph({ alignment: AlignmentType.RIGHT, children: [new TextRun({ text: doc.header, font: FONT, size: 15, color: MUTED })] })] }) },
    footers: {
      default: new Footer({
        children: [
          new Paragraph({
            alignment: AlignmentType.CENTER,
            children: [
              new TextRun({ text: doc.footer + "   |   Page ", font: FONT, size: 15, color: MUTED }),
              new TextRun({ children: [PageNumber.CURRENT], font: FONT, size: 15, color: MUTED }),
            ],
          }),
        ],
      }),
    },
    children: s.blocks.flatMap((b) => block(b, o)),
  };
});

const heading = (size, color, before, after) => ({
  run: { font: FONT, size, bold: true, color },
  paragraph: { spacing: { before, after }, keepNext: true },
});

const d = new Document({
  creator: doc.author || "",
  title: doc.title,
  description: doc.title,
  features: { updateFields: true },
  styles: {
    default: {
      document: { run: { font: FONT, size: 20, color: INK } },
      heading1: heading(32, ACCENT, 360, 160),
      heading2: heading(25, INK, 280, 120),
      heading3: heading(21, ACCENT, 200, 80),
    },
  },
  numbering: {
    config: [
      { reference: "bul", levels: [{ level: 0, format: LevelFormat.BULLET, text: "•", alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 400, hanging: 240 } } } }] },
      ...["num", "num2", "num3", "num4", "num5", "num6"].map((ref) => ({
        reference: ref,
        levels: [{ level: 0, format: LevelFormat.DECIMAL, text: "%1.", alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 440, hanging: 320 } } } }],
      })),
    ],
  },
  sections,
});

Packer.toBuffer(d).then((buf) => {
  fs.writeFileSync(outPath, buf);
  console.log("wrote", outPath, buf.length);
});
