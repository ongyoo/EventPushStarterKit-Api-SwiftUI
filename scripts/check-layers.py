#!/usr/bin/env python3
"""Enforces the layer arrows of Modules/Package.swift on every `import`.

Why: Xcode puts every module of a build in one folder, so `import DataLayer`
inside Features can compile even though Features does not depend on it
(it only needs DataLayer to be built earlier in the same build). Splitting
into several packages has the same hole. This check closes it.

Rules (read from Package.swift, nothing to maintain here):
  - a module imports only its direct `dependencies` (targets and products);
  - a test target imports its target and anything that target depends on;
  - the app target (App/Sources) imports only the `App` product (+ Domain).

    python3 scripts/check-layers.py       # also run by `make lint` and every Xcode build

Errors use Xcode's format, so they show inline in the editor.
"""
import hashlib
import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PACKAGE = os.path.join(ROOT, "Modules")
APP_SOURCES = os.path.join(ROOT, "App", "Sources")
APP_TARGET_ALLOWED = {"App", "Domain"}
CACHE = os.path.join(PACKAGE, ".build", "layer-rules.json")

IMPORT = re.compile(
    r'^\s*(?:@\w+(?:\([^)]*\))?\s+)*import\s+'
    r'(?:(?:struct|class|enum|protocol|func|var|let|typealias|actor)\s+)?(\w+)'
)


def manifest():
    """`swift package dump-package`, cached until Package.swift changes."""
    with open(os.path.join(PACKAGE, "Package.swift"), "rb") as f:
        digest = hashlib.sha256(f.read()).hexdigest()
    try:
        with open(CACHE) as f:
            cached = json.load(f)
        if cached.get("digest") == digest:
            return cached["manifest"]
    except (OSError, ValueError):
        pass
    # Clean environment: inside an Xcode build phase SDKROOT points to the iOS
    # SDK, and SwiftPM would try to evaluate the manifest for iOS and fail.
    keep = ("PATH", "HOME", "DEVELOPER_DIR", "TMPDIR", "USER")
    env = {key: os.environ[key] for key in keep if key in os.environ}
    result = subprocess.run(
        ["xcrun", "swift", "package", "dump-package", "--package-path", PACKAGE],
        capture_output=True, text=True, env=env,
    )
    if result.returncode != 0:
        sys.exit(f"error: could not read Modules/Package.swift: {result.stderr.strip()}")
    data = json.loads(result.stdout)
    os.makedirs(os.path.dirname(CACHE), exist_ok=True)
    with open(CACHE, "w") as f:
        json.dump({"digest": digest, "manifest": data}, f)
    return data


def direct_dependencies(target):
    names = set()
    for dependency in target["dependencies"]:
        for kind in ("byName", "target", "product"):
            if kind in dependency:
                names.add(dependency[kind][0])
    return names


def swift_files(folder):
    for path, _, files in os.walk(folder):
        for name in sorted(files):
            if name.endswith(".swift"):
                yield os.path.join(path, name)


def imports(path):
    with open(path, encoding="utf-8") as f:
        for number, line in enumerate(f, 1):
            match = IMPORT.match(line)
            if match:
                yield number, match.group(1)


def main():
    data = manifest()
    targets = {t["name"]: t for t in data["targets"]}
    direct = {name: direct_dependencies(t) for name, t in targets.items()}
    products = {dep for deps in direct.values() for dep in deps if dep not in targets}
    governed = set(targets) | products  # imports we have rules for (system modules are free)

    def closure(name, seen=None):
        seen = set() if seen is None else seen
        for dep in direct.get(name, ()):
            if dep not in seen:
                seen.add(dep)
                closure(dep, seen)
        return seen

    errors = []

    def check(folder, module, allowed):
        for path in swift_files(folder):
            for number, imported in imports(path):
                if imported in governed and imported != module and imported not in allowed:
                    rule = ", ".join(sorted(allowed & governed)) or "nothing"
                    errors.append(
                        f"{path}:{number}: error: {module} must not import {imported} "
                        f"(allowed by Modules/Package.swift: {rule}). "
                        f"Depend on a protocol in a lower layer instead, or move the code."
                    )

    for name, target in targets.items():
        kind = "Tests" if target["type"] == "test" else "Sources"
        folder = target.get("path") or os.path.join(kind, name)
        folder = os.path.join(PACKAGE, folder)
        if target["type"] == "test":
            tested = direct[name]
            allowed = set(tested)
            for dep in tested:
                allowed |= closure(dep)
        else:
            allowed = direct[name]
        check(folder, name, allowed)

    if os.path.isdir(APP_SOURCES):
        check(APP_SOURCES, "The app target", APP_TARGET_ALLOWED)

    for error in errors:
        print(error)
    if errors:
        print(f"✘ {len(errors)} layer violation(s). See docs/ARCHITECTURE.md.", file=sys.stderr)
        return 1
    print("✔ Layer dependencies follow Modules/Package.swift")
    return 0


if __name__ == "__main__":
    sys.exit(main())
