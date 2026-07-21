#!/usr/bin/env python3
"""Validate a company-deep-dive-report run using only the Python standard library."""

from __future__ import annotations

import argparse
import csv
import json
import re
import sys
from pathlib import Path


REQUIRED_FILES = (
    "analysis_brief.yaml",
    "evidence_ledger.csv",
    "claim_graph.json",
    "company_dossier.md",
)

EVIDENCE_COLUMNS = (
    "evidence_id",
    "collected_at",
    "published_at",
    "source_tier",
    "source_type",
    "publisher",
    "title",
    "url_or_path",
    "geography",
    "period",
    "evidence",
    "supports",
    "contradicts",
    "limitations",
)

REPORT_SECTIONS = (
    "Executive Thesis",
    "Company at a Glance",
    "Business Model Map",
    "KPI Driver Tree",
    "Segment Economics",
    "Market and Competition",
    "Moat System",
    "Growth Engines",
    "Risks and Contradictions",
    "Scenarios",
    "Strategic Watchlist",
    "Methodology and Limitations",
)


def add_error(errors: list[str], message: str) -> None:
    errors.append(f"ERROR: {message}")


def add_warning(warnings: list[str], message: str) -> None:
    warnings.append(f"WARN: {message}")


def validate_evidence(path: Path, errors: list[str], warnings: list[str]) -> set[str]:
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        missing = [column for column in EVIDENCE_COLUMNS if column not in (reader.fieldnames or [])]
        if missing:
            add_error(errors, f"evidence_ledger.csv is missing columns: {', '.join(missing)}")
            return set()

        ids: set[str] = set()
        rows = list(reader)
        if not rows:
            add_warning(warnings, "evidence_ledger.csv has no evidence rows")
        for line_number, row in enumerate(rows, start=2):
            evidence_id = (row.get("evidence_id") or "").strip()
            if not re.fullmatch(r"E\d{3,}", evidence_id):
                add_error(errors, f"invalid evidence_id at CSV line {line_number}: {evidence_id!r}")
            elif evidence_id in ids:
                add_error(errors, f"duplicate evidence_id: {evidence_id}")
            ids.add(evidence_id)
            if (row.get("source_tier") or "").strip() not in {"A", "B", "C", "D"}:
                add_error(errors, f"invalid source_tier for {evidence_id}")
            for field in ("collected_at", "publisher", "title", "url_or_path", "evidence"):
                if not (row.get(field) or "").strip():
                    add_error(errors, f"{evidence_id or 'unknown evidence'} is missing {field}")
    return ids


def validate_claims(
    path: Path, evidence_ids: set[str], errors: list[str], warnings: list[str]
) -> set[str]:
    try:
        data = json.loads(path.read_text(encoding="utf-8-sig"))
    except json.JSONDecodeError as exc:
        add_error(errors, f"claim_graph.json is invalid JSON: {exc}")
        return set()

    claims = data.get("claims")
    if not isinstance(claims, list):
        add_error(errors, "claim_graph.json must contain a claims array")
        return set()

    claim_ids: set[str] = set()
    for index, claim in enumerate(claims, start=1):
        if not isinstance(claim, dict):
            add_error(errors, f"claim #{index} is not an object")
            continue
        claim_id = str(claim.get("claim_id", "")).strip()
        if not re.fullmatch(r"C\d{3,}", claim_id):
            add_error(errors, f"invalid claim_id at claim #{index}: {claim_id!r}")
        elif claim_id in claim_ids:
            add_error(errors, f"duplicate claim_id: {claim_id}")
        claim_ids.add(claim_id)

        if claim.get("classification") not in {"FACT", "INFERENCE", "HYPOTHESIS", "UNKNOWN"}:
            add_error(errors, f"{claim_id} has an invalid classification")
        if claim.get("confidence") not in {"HIGH", "MEDIUM", "LOW"}:
            add_error(errors, f"{claim_id} has an invalid confidence")
        if not str(claim.get("statement", "")).strip():
            add_error(errors, f"{claim_id} has no statement")

        linked = claim.get("evidence_ids", [])
        counter = claim.get("counterevidence_ids", [])
        if not isinstance(linked, list) or not isinstance(counter, list):
            add_error(errors, f"{claim_id} evidence fields must be arrays")
            continue
        unknown = (set(linked) | set(counter)) - evidence_ids
        if unknown:
            add_error(errors, f"{claim_id} references unknown evidence IDs: {', '.join(sorted(unknown))}")

        if claim.get("tier") == 1:
            if len(set(linked)) < 2:
                add_warning(warnings, f"Tier 1 claim {claim_id} has fewer than two evidence items")
            if not str(claim.get("falsifier", "")).strip():
                add_warning(warnings, f"Tier 1 claim {claim_id} has no falsifier")
    return claim_ids


def validate_report(path: Path, claim_ids: set[str], errors: list[str], warnings: list[str]) -> None:
    text = path.read_text(encoding="utf-8-sig")
    for section in REPORT_SECTIONS:
        if section.lower() not in text.lower():
            add_warning(warnings, f"company_dossier.md is missing section: {section}")

    referenced_claims = set(re.findall(r"\bC\d{3,}\b", text))
    unknown = referenced_claims - claim_ids
    if unknown:
        add_error(errors, f"company_dossier.md references unknown claim IDs: {', '.join(sorted(unknown))}")
    unreferenced = claim_ids - referenced_claims
    if unreferenced:
        add_warning(warnings, f"claims not referenced in company_dossier.md: {', '.join(sorted(unreferenced))}")


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate a company deep-dive run directory")
    parser.add_argument("run_directory", type=Path)
    args = parser.parse_args()
    run_dir = args.run_directory.resolve()
    errors: list[str] = []
    warnings: list[str] = []

    if not run_dir.is_dir():
        print(f"ERROR: run directory does not exist: {run_dir}")
        return 2

    for filename in REQUIRED_FILES:
        if not (run_dir / filename).is_file():
            add_error(errors, f"missing required file: {filename}")

    evidence_ids: set[str] = set()
    claim_ids: set[str] = set()
    if (run_dir / "evidence_ledger.csv").is_file():
        evidence_ids = validate_evidence(run_dir / "evidence_ledger.csv", errors, warnings)
    if (run_dir / "claim_graph.json").is_file():
        claim_ids = validate_claims(run_dir / "claim_graph.json", evidence_ids, errors, warnings)
    if (run_dir / "company_dossier.md").is_file():
        validate_report(run_dir / "company_dossier.md", claim_ids, errors, warnings)

    for message in errors + warnings:
        print(message)
    print(f"SUMMARY: errors={len(errors)} warnings={len(warnings)}")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
