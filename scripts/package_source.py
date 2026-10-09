#!/usr/bin/env python3
"""Create a JEV source archive, including checked-out dependency sources.

Build outputs, Git metadata, IDE state and local tools are excluded. This does
not create Windows binaries, an installer or a runtime distribution.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import zipfile


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    output = args.output.resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    if not (root / "third_party/OpenCC/CMakeLists.txt").is_file():
        raise SystemExit("OpenCC is missing; initialize the submodule first.")
    excluded_dirs = {".git", ".vs", "__pycache__"}
    excluded_root_dirs = {"dist", "bin", "lib", "obj", "out"}
    files = []
    for path in root.rglob("*"):
        relative = path.relative_to(root)
        if (not path.is_file() or path.is_symlink() or path.resolve() == output
                or path.resolve() == output.with_suffix(output.suffix + ".sha256")
                or path.name in {".git", "SOURCE-ARCHIVE.json"}
                or any(part in excluded_dirs for part in relative.parts[:-1])
                or (len(relative.parts) > 1 and
                    (relative.parts[0] in excluded_root_dirs or
                     relative.parts[0].startswith("build")))
                or path.suffix in {".pyc", ".tmp", ".bak"}):
            continue
        files.append(path)
    files.sort()
    revision = "source-archive"
    dirty = None
    if (root / ".git").exists():
        revision = subprocess.check_output(
            ["git", "rev-parse", "HEAD"], cwd=root, text=True).strip()
        dirty = bool(subprocess.check_output(
            ["git", "status", "--porcelain"], cwd=root, text=True).strip())
    metadata = {
        "product": "JEV-IME",
        "version": json.loads((root / "data/jev-product.json").read_text(encoding="utf-8"))["version"],
        "kind": "source-only",
        "sourceRevision": revision,
        "workingTreeChanges": dirty,
        "files": [{"path": p.relative_to(root).as_posix(),
                   "sha256": hashlib.sha256(p.read_bytes()).hexdigest()}
                  for p in files],
    }
    with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED,
                         compresslevel=9) as archive:
        for path in files:
            archive.write(path, "JEV-IME/" + path.relative_to(root).as_posix())
        archive.writestr("JEV-IME/SOURCE-ARCHIVE.json",
                         json.dumps(metadata, ensure_ascii=False, indent=2) + "\n")
    with zipfile.ZipFile(output) as archive:
        if archive.testzip() is not None:
            raise SystemExit("Archive CRC verification failed.")
    digest = hashlib.sha256(output.read_bytes()).hexdigest()
    output.with_suffix(output.suffix + ".sha256").write_text(
        f"{digest}  {output.name}\n", encoding="ascii")
    print(f"Source archive: {output} ({len(files)} files, {output.stat().st_size} bytes)")
    print(f"SHA-256: {digest}")


if __name__ == "__main__":
    main()
