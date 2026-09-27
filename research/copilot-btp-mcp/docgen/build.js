// build.js — renders content.js into a .docx with the docx npm package.
// Usage: NODE_PATH=<dir containing node_modules> node build.js content.js out.docx
'use strict'
const path = require('path')
const fs = require('fs')
const {
  Document, Packer, Paragraph, TextRun, HeadingLevel, AlignmentType, Table, TableRow, TableCell,
  WidthType, ShadingType, BorderStyle, ExternalHyperlink, LevelFormat, PageBreak, TableOfContents,
  Header, Footer, PageNumber, TabStopType, VerticalAlign,
} = require('docx')

const [, , contentPath, outPath, mdPath] = process.argv
if (!contentPath || !outPath) { console.error('usage: node build.js content.js out.docx [out.md]'); process.exit(2) }
const doc = require(path.resolve(contentPath))

// ---------- optional Markdown export (same content, for git-readable review) ----------
function toMarkdown(d) {
  const out = [`# ${d.title}`, '', d.subtitle ? `_${d.subtitle}_` : '', '']
  Object.entries(d.meta || {}).forEach(([k, v]) => out.push(`- **${k}:** ${v}`))
  out.push('')
  const md = s => String(s).replace(/~([^~]+)~/g, '_$1_')
  const cell = c => (Array.isArray(c) ? c.map(md).join('<br>') : md(c)).replace(/\|/g, '\\|')
  for (const b of d.body) {
    if (typeof b === 'string') { out.push(md(b), ''); continue }
    switch (b.t) {
      case 'h1': out.push(`## ${md(b.x)}`, ''); break
      case 'h2': out.push(`### ${md(b.x)}`, ''); break
      case 'h3': out.push(`#### ${md(b.x)}`, ''); break
      case 'p': case 'small': out.push(md(b.x), ''); break
      case 'bullets': b.x.forEach(li => out.push(`${'  '.repeat(b.level || 0)}- ${md(li)}`)); out.push(''); break
      case 'numbered': case 'steps': b.x.forEach((li, i) => out.push(`${i + 1}. ${md(li)}`)); out.push(''); break
      case 'callout': { const items = Array.isArray(b.x) ? b.x : [b.x]; if (b.title) out.push(`> **${b.title}**`, '>'); items.forEach(l => out.push(`> ${md(l)}`)); out.push(''); break }
      case 'table': out.push(`| ${b.cols.map(cell).join(' | ')} |`, `| ${b.cols.map(() => '---').join(' | ')} |`); b.rows.forEach(r => out.push(`| ${r.map(cell).join(' | ')} |`)); out.push(''); break
      case 'toc': case 'pagebreak': case 'spacer': break
    }
  }
  return out.join('\n')
}
if (mdPath) fs.writeFileSync(mdPath, toMarkdown(doc))

// ---------- palette / metrics ----------
const FONT = 'Calibri'
const NAVY = '1F3864'
const TEAL = '2E75B6'
const GREY = '595959'
const LIGHT = 'F2F2F2'
const HEAD = 'D9E2F3'
const CALLOUT = 'FFF2CC'
const RISK = 'FBE5D6'
const OK = 'E2EFDA'
const PAGE_W = 11906, PAGE_H = 16838          // A4 in DXA
const MARGIN = 1134                           // 2 cm
const CONTENT_W = PAGE_W - 2 * MARGIN         // 9638

// ---------- inline markup: **bold**, `code`, [text](url), ~italic~ ----------
// (tilde, not underscore, for italics: SAP names like API_PURCHASEORDER_PROCESS_SRV are full of underscores)
function inline(text, base = {}) {
  const runs = []
  const re = /(\*\*[^*]+\*\*|`[^`]+`|\[[^\]]+\]\([^)]+\)|~[^~]+~)/g
  let last = 0, m
  while ((m = re.exec(text)) !== null) {
    if (m.index > last) runs.push(new TextRun({ text: text.slice(last, m.index), font: FONT, ...base }))
    const tok = m[0]
    if (tok.startsWith('**')) runs.push(new TextRun({ text: tok.slice(2, -2), bold: true, font: FONT, ...base }))
    else if (tok.startsWith('`')) runs.push(new TextRun({ text: tok.slice(1, -1), font: 'Consolas', size: (base.size || 20) - 1, color: '7F0000', ...base, }))
    else if (tok.startsWith('~')) runs.push(new TextRun({ text: tok.slice(1, -1), italics: true, font: FONT, ...base }))
    else {
      const mm = /\[([^\]]+)\]\(([^)]+)\)/.exec(tok)
      runs.push(new ExternalHyperlink({
        link: mm[2],
        children: [new TextRun({ text: mm[1], style: 'Hyperlink', font: FONT, ...base })],
      }))
    }
    last = m.index + tok.length
  }
  if (last < text.length) runs.push(new TextRun({ text: text.slice(last), font: FONT, ...base }))
  return runs
}

const P = (text, opts = {}) => new Paragraph({ children: inline(text, opts.run || {}), spacing: { after: 120, line: 276 }, ...opts.para })

// ---------- block renderers ----------
function render(block) {
  if (typeof block === 'string') return [P(block)]
  switch (block.t) {
    case 'h1': return [new Paragraph({ heading: HeadingLevel.HEADING_1, children: inline(block.x), pageBreakBefore: !!block.pb, spacing: { before: 360, after: 160 } })]
    case 'h2': return [new Paragraph({ heading: HeadingLevel.HEADING_2, children: inline(block.x), spacing: { before: 280, after: 120 } })]
    case 'h3': return [new Paragraph({ heading: HeadingLevel.HEADING_3, children: inline(block.x), spacing: { before: 200, after: 80 } })]
    case 'p': return [P(block.x)]
    case 'small': return [P(block.x, { run: { size: 18, color: GREY } })]
    case 'bullets': return block.x.map(li => new Paragraph({ children: inline(li), numbering: { reference: 'bullets', level: block.level || 0 }, spacing: { after: 60, line: 264 } }))
    case 'numbered': return block.x.map(li => new Paragraph({ children: inline(li), numbering: { reference: `num-${block.id}`, level: 0 }, spacing: { after: 60, line: 264 } }))
    case 'steps': {   // numbered with a bold lead-in "Title — detail"
      return block.x.map(li => new Paragraph({ children: inline(li), numbering: { reference: `num-${block.id}`, level: 0 }, spacing: { after: 80, line: 264 } }))
    }
    case 'callout': return [calloutTable(block.x, block.kind || 'note', block.title)]
    case 'table': return [dataTable(block)]
    case 'pagebreak': return [new Paragraph({ children: [new PageBreak()] })]
    case 'toc': return [
      new Paragraph({ heading: HeadingLevel.HEADING_1, children: [new TextRun({ text: 'Contents', font: FONT })], spacing: { after: 160 } }),
      new TableOfContents('Contents', { hyperlink: true, headingStyleRange: '1-2' }),
      new Paragraph({ children: [new PageBreak()] }),
    ]
    case 'spacer': return [new Paragraph({ spacing: { after: block.x || 200 } })]
    default: throw new Error('unknown block ' + JSON.stringify(block).slice(0, 80))
  }
}

function cellParas(content, opts = {}) {
  const items = Array.isArray(content) ? content : [content]
  return items.map(c => new Paragraph({ children: inline(String(c), { size: opts.size || 18, bold: opts.bold, color: opts.color }), spacing: { after: 40, line: 252 } }))
}

function border(color = 'BFBFBF') { const b = { style: BorderStyle.SINGLE, size: 4, color }; return { top: b, bottom: b, left: b, right: b } }

function dataTable({ cols, widths, rows, header = true, zebra = true, font = 18 }) {
  const total = CONTENT_W
  const w = (widths || cols.map(() => 1 / cols.length)).map(f => Math.round(f * total))
  const mk = (cells, isHead, i) => new TableRow({
    tableHeader: isHead,
    children: cells.map((c, j) => new TableCell({
      width: { size: w[j], type: WidthType.DXA },
      borders: border(),
      shading: isHead ? { fill: HEAD, type: ShadingType.CLEAR, color: 'auto' } : (zebra && i % 2 ? { fill: LIGHT, type: ShadingType.CLEAR, color: 'auto' } : undefined),
      margins: { top: 60, bottom: 60, left: 90, right: 90 },
      verticalAlign: VerticalAlign.TOP,
      children: cellParas(c, { bold: isHead, size: font, color: isHead ? NAVY : undefined }),
    })),
  })
  const trs = []
  if (header) trs.push(mk(cols, true, 0))
  rows.forEach((r, i) => trs.push(mk(r, false, i)))
  return new Table({ width: { size: total, type: WidthType.DXA }, columnWidths: w, rows: trs })
}

function calloutTable(lines, kind, title) {
  const fill = kind === 'risk' ? RISK : kind === 'ok' ? OK : CALLOUT
  const items = Array.isArray(lines) ? lines : [lines]
  const children = []
  if (title) children.push(new Paragraph({ children: [new TextRun({ text: title, bold: true, font: FONT, size: 20, color: NAVY })], spacing: { after: 60 } }))
  items.forEach(l => children.push(new Paragraph({ children: inline(l, { size: 19 }), spacing: { after: 60, line: 264 } })))
  return new Table({
    width: { size: CONTENT_W, type: WidthType.DXA }, columnWidths: [CONTENT_W],
    rows: [new TableRow({ children: [new TableCell({ width: { size: CONTENT_W, type: WidthType.DXA }, borders: border('BF9000'), shading: { fill, type: ShadingType.CLEAR, color: 'auto' }, margins: { top: 100, bottom: 100, left: 140, right: 140 }, children })] })],
  })
}

// ---------- cover ----------
function cover(d) {
  const out = []
  out.push(new Paragraph({ spacing: { before: 2400 } }))
  out.push(new Paragraph({ children: [new TextRun({ text: d.org || '', font: FONT, size: 24, color: TEAL, bold: true })], spacing: { after: 240 } }))
  out.push(new Paragraph({ children: [new TextRun({ text: d.title, font: FONT, size: 52, bold: true, color: NAVY })], spacing: { after: 200 } }))
  if (d.subtitle) out.push(new Paragraph({ children: [new TextRun({ text: d.subtitle, font: FONT, size: 28, color: GREY })], spacing: { after: 600 } }))
  const meta = d.meta || {}
  const rows = Object.entries(meta).map(([k, v]) => [k, v])
  out.push(new Table({
    width: { size: 6000, type: WidthType.DXA }, columnWidths: [1800, 4200],
    rows: rows.map(([k, v]) => new TableRow({ children: [
      new TableCell({ width: { size: 1800, type: WidthType.DXA }, borders: border('FFFFFF'), children: cellParas(k, { bold: true, size: 20, color: NAVY }) }),
      new TableCell({ width: { size: 4200, type: WidthType.DXA }, borders: border('FFFFFF'), children: cellParas(v, { size: 20 }) }),
    ] })),
  }))
  if (d.confidentiality) {
    out.push(new Paragraph({ spacing: { before: 1200 } }))
    out.push(new Paragraph({ children: [new TextRun({ text: d.confidentiality, font: FONT, size: 18, italics: true, color: GREY })] }))
  }
  out.push(new Paragraph({ children: [new PageBreak()] }))
  return out
}

// ---------- numbering ----------
const numIds = new Set()
;(function collect(blocks) { blocks.forEach(b => { if (b && (b.t === 'numbered' || b.t === 'steps')) numIds.add(b.id) }) })(doc.body)
const numbering = {
  config: [
    { reference: 'bullets', levels: [
      { level: 0, format: LevelFormat.BULLET, text: '•', alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 540, hanging: 270 } } } },
      { level: 1, format: LevelFormat.BULLET, text: '–', alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 1000, hanging: 270 } } } },
    ] },
    ...[...numIds].map(id => ({ reference: `num-${id}`, levels: [
      { level: 0, format: LevelFormat.DECIMAL, text: '%1.', alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 540, hanging: 360 } } } },
    ] })),
  ],
}

// ---------- assemble ----------
const body = [...cover(doc), ...doc.body.flatMap(render)]

const document = new Document({
  creator: doc.author || '',
  title: doc.title,
  description: doc.subtitle || '',
  styles: {
    default: { document: { run: { font: FONT, size: 21 } } },
    paragraphStyles: [
      { id: 'Heading1', name: 'Heading 1', basedOn: 'Normal', next: 'Normal', quickFormat: true, run: { size: 32, bold: true, color: NAVY, font: FONT }, paragraph: { spacing: { before: 360, after: 160 }, outlineLevel: 0 } },
      { id: 'Heading2', name: 'Heading 2', basedOn: 'Normal', next: 'Normal', quickFormat: true, run: { size: 26, bold: true, color: TEAL, font: FONT }, paragraph: { spacing: { before: 280, after: 120 }, outlineLevel: 1 } },
      { id: 'Heading3', name: 'Heading 3', basedOn: 'Normal', next: 'Normal', quickFormat: true, run: { size: 22, bold: true, color: NAVY, font: FONT }, paragraph: { spacing: { before: 200, after: 80 }, outlineLevel: 2 } },
    ],
    characterStyles: [{ id: 'Hyperlink', name: 'Hyperlink', run: { color: '0563C1', underline: {} } }],
  },
  numbering,
  features: { updateFields: true },
  sections: [{
    properties: { page: { size: { width: PAGE_W, height: PAGE_H }, margin: { top: MARGIN, bottom: MARGIN, left: MARGIN, right: MARGIN } } },
    headers: { default: new Header({ children: [new Paragraph({ children: [new TextRun({ text: `${doc.org || ''}  |  ${doc.title}`, font: FONT, size: 16, color: GREY })], border: { bottom: { style: BorderStyle.SINGLE, size: 4, color: 'BFBFBF' } } })] }) },
    footers: { default: new Footer({ children: [new Paragraph({ tabStops: [{ type: TabStopType.RIGHT, position: CONTENT_W }], children: [
      new TextRun({ text: doc.footer || '', font: FONT, size: 16, color: GREY }),
      new TextRun({ text: '\tPage ', font: FONT, size: 16, color: GREY }),
      new TextRun({ children: [PageNumber.CURRENT], font: FONT, size: 16, color: GREY }),
      new TextRun({ text: ' of ', font: FONT, size: 16, color: GREY }),
      new TextRun({ children: [PageNumber.TOTAL_PAGES], font: FONT, size: 16, color: GREY }),
    ] })] }) },
    children: body,
  }],
})

Packer.toBuffer(document).then(buf => { fs.writeFileSync(outPath, buf); console.log('wrote', outPath, buf.length, 'bytes') })
