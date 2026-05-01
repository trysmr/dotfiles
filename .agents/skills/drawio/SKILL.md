---
name: drawio
description: Always use when the user asks to create, generate, draw, or design a diagram, flowchart, architecture diagram, ER diagram, sequence diagram, class diagram, network diagram, mockup, wireframe, UI sketch, draw.io, drawio, .drawio, or diagram export to PNG, SVG, or PDF.
---

# Draw.io Diagram

draw.ioネイティブの `.drawio` XMLを生成する。必要に応じてPNG、SVG、PDFへエクスポートする。

## Workflow

1. 要件から図の種類、対象、出力形式を確認する。指定がなければ `.drawio` を作る。
2. mxGraphModel XMLを直接生成する。MermaidやCSVを中間形式にしない。
3. `.drawio` ファイルを書き出す。
4. PNG/SVG/PDF指定がある場合はdraw.io CLIを探し、`--embed-diagram` 付きでエクスポートする。
5. CLIが見つからない場合は `.drawio` を残し、エクスポート未実施を報告する。

## CLI

macOS:

```bash
/Applications/draw.io.app/Contents/MacOS/draw.io
```

PATHにある場合:

```bash
drawio -x -f png -e -b 10 -o output.drawio.png input.drawio
```

## XML Rules

- ルートは `<mxGraphModel><root><mxCell id="0"/><mxCell id="1" parent="0"/>...` を含める。
- XMLコメントは入れない。
- 属性値の `&`, `<`, `>`, `"` はエスケープする。
- edgeには `<mxGeometry relative="1" as="geometry"/>` を含める。
- IDは一意にする。
