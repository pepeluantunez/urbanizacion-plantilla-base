#!/usr/bin/env python3
"""Build a searchable normativa corpus from local PDF sources."""

from __future__ import annotations

import argparse
import csv
import json
import re
from collections import Counter
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable

from pypdf import PdfReader


@dataclass
class CorpusItem:
    item_id: str
    title: str
    category: str
    domain: str
    pdf_path: str
    text_path: str
    pages: int
    characters: int
    status: str
    error: str
    keywords: list[str]

    def to_json(self) -> dict[str, object]:
        return {
            "id": self.item_id,
            "title": self.title,
            "category": self.category,
            "domain": self.domain,
            "pdf_path": self.pdf_path,
            "text_path": self.text_path,
            "pages": self.pages,
            "characters": self.characters,
            "status": self.status,
            "error": self.error,
            "keywords": self.keywords,
        }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Extract PDF text and build a searchable normativa corpus."
    )
    parser.add_argument("--source-root", required=True, help="Folder with source PDFs.")
    parser.add_argument(
        "--normativa-root",
        required=True,
        help="Normativa root containing 01_texto_extraido and 02_indices.",
    )
    parser.add_argument(
        "--catalog-path",
        help="Optional explicit path for catalog.json. Defaults to <normativa-root>/catalog.json.",
    )
    parser.add_argument(
        "--name-filter",
        help="Optional case-insensitive substring filter for PDF relative paths.",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=0,
        help="Optional limit for processed PDFs. 0 means all.",
    )
    parser.add_argument(
        "--skip-existing",
        action="store_true",
        help="Do not rewrite extracted text files if they already exist.",
    )
    return parser.parse_args()


def normalize_relpath(path: Path) -> str:
    return path.as_posix()


def slug_keywords(parts: Iterable[str]) -> list[str]:
    values: list[str] = []
    seen: set[str] = set()
    for part in parts:
        token = re.sub(r"[^A-Za-z0-9._/-]+", " ", part).strip().lower()
        if not token:
            continue
        for item in token.split():
            if item not in seen:
                seen.add(item)
                values.append(item)
    return values


def first_nonempty_line(text: str, fallback: str) -> str:
    for line in text.splitlines():
        candidate = re.sub(r"\s+", " ", line).strip()
        if len(candidate) >= 8:
            return candidate
    return fallback


def extract_pdf_text(pdf_path: Path) -> tuple[list[str], int]:
    reader = PdfReader(str(pdf_path))
    page_texts: list[str] = []
    for page in reader.pages:
        text = page.extract_text() or ""
        page_texts.append(text.strip())
    return page_texts, len(reader.pages)


def write_text_markdown(
    target_path: Path,
    pdf_relpath: str,
    title: str,
    pages: int,
    status: str,
    page_texts: list[str],
) -> int:
    target_path.parent.mkdir(parents=True, exist_ok=True)
    lines = [
        "# Extracted Normativa Text",
        "",
        f"- source_pdf: `{pdf_relpath}`",
        f"- title_guess: {title}",
        f"- pages: {pages}",
        f"- status: {status}",
        "",
    ]
    for index, text in enumerate(page_texts, start=1):
        lines.append(f"## Page {index}")
        lines.append("")
        lines.append(text if text else "[[EMPTY_PAGE_TEXT]]")
        lines.append("")
    content = "\n".join(lines).strip() + "\n"
    target_path.write_text(content, encoding="utf-8", newline="\n")
    return len(content)


def build_markdown_index(items: list[CorpusItem], generated_at: str) -> str:
    lines = [
        "# Catalogo de normativa extraida",
        "",
        f"Fecha UTC: {generated_at}",
        "",
        "| id | categoria | dominio | estado | paginas | caracteres | titulo |",
        "|---|---|---|---|---:|---:|---|",
    ]
    for item in items:
        title = item.title.replace("|", "/")
        lines.append(
            f"| `{item.item_id}` | `{item.category}` | `{item.domain}` | "
            f"`{item.status}` | {item.pages} | {item.characters} | {title} |"
        )
    return "\n".join(lines) + "\n"


def build_summary(items: list[CorpusItem]) -> dict[str, object]:
    by_status = Counter(item.status for item in items)
    by_category = Counter(item.category for item in items)
    by_domain = Counter(item.domain for item in items)
    return {
        "pdf_count": len(items),
        "status_counts": dict(sorted(by_status.items())),
        "category_counts": dict(sorted(by_category.items())),
        "domain_counts": dict(sorted(by_domain.items())),
    }


def main() -> int:
    args = parse_args()
    source_root = Path(args.source_root).resolve()
    normativa_root = Path(args.normativa_root).resolve()
    text_root = normativa_root / "01_texto_extraido"
    index_root = normativa_root / "02_indices"
    catalog_path = (
        Path(args.catalog_path).resolve()
        if args.catalog_path
        else (normativa_root / "catalog.json")
    )

    if not source_root.exists():
        raise SystemExit(f"Source root does not exist: {source_root}")

    text_root.mkdir(parents=True, exist_ok=True)
    index_root.mkdir(parents=True, exist_ok=True)
    catalog_path.parent.mkdir(parents=True, exist_ok=True)

    pdf_paths = sorted(source_root.rglob("*.pdf"))
    if args.name_filter:
        filter_value = args.name_filter.lower()
        pdf_paths = [
            path
            for path in pdf_paths
            if filter_value in normalize_relpath(path.relative_to(source_root)).lower()
        ]
    if args.limit > 0:
        pdf_paths = pdf_paths[: args.limit]

    items: list[CorpusItem] = []
    for pdf_path in pdf_paths:
        rel_pdf = pdf_path.relative_to(source_root)
        rel_pdf_norm = normalize_relpath(Path("00_fuentes_pdf") / rel_pdf)
        rel_text = rel_pdf.with_suffix(".md")
        rel_text_norm = normalize_relpath(Path("01_texto_extraido") / rel_text)
        text_path = text_root / rel_text

        category = rel_pdf.parts[0] if len(rel_pdf.parts) >= 2 else "sin_categoria"
        domain = rel_pdf.parts[1] if len(rel_pdf.parts) >= 3 else "sin_dominio"
        item_id = pdf_path.stem
        keywords = slug_keywords([item_id, category, domain, *rel_pdf.parts])

        try:
            page_texts, pages = extract_pdf_text(pdf_path)
            joined_text = "\n\n".join(page_texts).strip()
            title = first_nonempty_line(joined_text, item_id)
            status = "ok" if joined_text else "empty"
            error = ""
            if not (args.skip_existing and text_path.exists()):
                characters = write_text_markdown(
                    text_path, rel_pdf_norm, title, pages, status, page_texts
                )
            else:
                characters = len(text_path.read_text(encoding="utf-8"))
        except Exception as exc:  # pragma: no cover - defensive
            pages = 0
            characters = 0
            title = item_id
            status = "error"
            error = str(exc)
            if not (args.skip_existing and text_path.exists()):
                write_text_markdown(text_path, rel_pdf_norm, title, pages, status, [error])

        items.append(
            CorpusItem(
                item_id=item_id,
                title=title,
                category=category,
                domain=domain,
                pdf_path=rel_pdf_norm,
                text_path=rel_text_norm,
                pages=pages,
                characters=characters,
                status=status,
                error=error,
                keywords=keywords,
            )
        )

    generated_at = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S")
    payload = {
        "version": "2026-04-28",
        "generated_at_utc": generated_at,
        "source_root": normalize_relpath(Path("00_fuentes_pdf")),
        "text_root": normalize_relpath(Path("01_texto_extraido")),
        "items": [item.to_json() for item in items],
    }
    catalog_path.write_text(
        json.dumps(payload, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
        newline="\n",
    )

    csv_path = index_root / "normativa_catalogo.csv"
    with csv_path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle)
        writer.writerow(
            [
                "id",
                "title",
                "category",
                "domain",
                "pdf_path",
                "text_path",
                "pages",
                "characters",
                "status",
                "error",
            ]
        )
        for item in items:
            writer.writerow(
                [
                    item.item_id,
                    item.title,
                    item.category,
                    item.domain,
                    item.pdf_path,
                    item.text_path,
                    item.pages,
                    item.characters,
                    item.status,
                    item.error,
                ]
            )

    md_path = index_root / "normativa_catalogo.md"
    md_path.write_text(build_markdown_index(items, generated_at), encoding="utf-8", newline="\n")

    summary_path = index_root / "normativa_resumen.json"
    summary_payload = {
        "generated_at_utc": generated_at,
        **build_summary(items),
    }
    summary_path.write_text(
        json.dumps(summary_payload, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
        newline="\n",
    )

    print(f"Corpus built: {len(items)} PDF(s)")
    print(f"Catalog: {catalog_path}")
    print(f"CSV: {csv_path}")
    print(f"Markdown: {md_path}")
    print(f"Summary: {summary_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
