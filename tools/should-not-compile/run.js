#!/usr/bin/env bun
// tools/should-not-compile/run.js
//
// Tier B "should-not-compile" check (SPEC.md step 6). Every `.elm` file under
// `Reject/` must fail `elm make` for a genuine type reason; `Accept/Control.elm`
// is the positive control and must compile, proving the harness itself works.
//
// Usage (works from any cwd):
//   bun tools/should-not-compile/run.js
//   bun /absolute/path/to/tools/should-not-compile/run.js
//
// How it works:
//   1. Build one temporary Elm "application" project whose source-directories
//      are [<repo>/src, <this directory>] and whose dependencies match
//      demo/elm.json (the same deps the library needs, plus elm/browser and
//      elm/url which demo already resolved). Fixture files stay put; only a
//      throwaway elm.json + elm-stuff live in the temp dir.
//   2. Compile every Reject/*.elm and Accept/Control.elm fixture in ONE
//      `elm make ... --report=json` invocation, so dependency resolution and
//      package compilation happen once ("one shared temp project for
//      speed"), not once per fixture.
//   3. Parse the JSON error report. For each Reject fixture, look up which
//      error headers (e.g. "TYPE MISMATCH") elm actually produced for that
//      file and compare against tools/should-not-compile/manifest.json. For
//      Accept/Control.elm, it must NOT appear in the error report at all.
//   4. Print a table and exit 1 if anything doesn't match.

import { existsSync, mkdtempSync, readdirSync, readFileSync, rmSync, writeFileSync } from "fs";
import { tmpdir } from "os";
import { join, resolve, relative } from "path";
import { spawnSync } from "child_process";

const SCRIPT_DIR = import.meta.dir;
const REPO_ROOT = resolve(SCRIPT_DIR, "..", "..");
const REJECT_DIR = join(SCRIPT_DIR, "Reject");
const ACCEPT_DIR = join(SCRIPT_DIR, "Accept");
const MANIFEST_PATH = join(SCRIPT_DIR, "manifest.json");
const DEMO_ELM_JSON_PATH = join(REPO_ROOT, "demo", "elm.json");
const REPO_SRC = join(REPO_ROOT, "src");

function fail(message) {
    console.error(`should-not-compile: ${message}`);
    process.exit(1);
}

if (!existsSync(MANIFEST_PATH)) {
    fail(`manifest not found at ${MANIFEST_PATH}`);
}
if (!existsSync(DEMO_ELM_JSON_PATH)) {
    fail(`demo/elm.json not found at ${DEMO_ELM_JSON_PATH} (needed for dependency versions)`);
}
if (!existsSync(REJECT_DIR)) {
    fail(`Reject/ directory not found at ${REJECT_DIR}`);
}

const manifest = JSON.parse(readFileSync(MANIFEST_PATH, "utf8"));
const demoElmJson = JSON.parse(readFileSync(DEMO_ELM_JSON_PATH, "utf8"));

const rejectFiles = readdirSync(REJECT_DIR)
    .filter((name) => name.endsWith(".elm"))
    .sort()
    .map((name) => join(REJECT_DIR, name));

const acceptFiles = existsSync(ACCEPT_DIR)
    ? readdirSync(ACCEPT_DIR)
          .filter((name) => name.endsWith(".elm"))
          .sort()
          .map((name) => join(ACCEPT_DIR, name))
    : [];

if (rejectFiles.length === 0) {
    fail(`no fixtures found in ${REJECT_DIR}`);
}
if (acceptFiles.length === 0) {
    fail(`no positive control found in ${ACCEPT_DIR} (expected Accept/Control.elm)`);
}

const manifestKeys = Object.keys(manifest);
const rejectRelPaths = rejectFiles.map((f) => relative(SCRIPT_DIR, f));
for (const rel of rejectRelPaths) {
    if (!manifestKeys.includes(rel)) {
        fail(`fixture ${rel} has no entry in manifest.json`);
    }
}
for (const key of manifestKeys) {
    if (!rejectRelPaths.includes(key)) {
        fail(`manifest.json lists ${key}, but that fixture file does not exist`);
    }
}

// --- 1. Build the shared temp elm project ----------------------------------

const tempDir = mkdtempSync(join(tmpdir(), "daisy-should-not-compile-"));

const tempElmJson = {
    type: "application",
    "source-directories": [REPO_SRC, SCRIPT_DIR],
    "elm-version": "0.19.1",
    dependencies: demoElmJson.dependencies,
    "test-dependencies": demoElmJson["test-dependencies"] ?? { direct: {}, indirect: {} },
};

writeFileSync(join(tempDir, "elm.json"), JSON.stringify(tempElmJson, null, 4));

// --- 2. Compile every fixture in one invocation -----------------------------

const allFiles = [...rejectFiles, ...acceptFiles];

const elmResult = spawnSync(
    "elm",
    ["make", ...allFiles, "--output=/dev/null", "--report=json"],
    { cwd: tempDir, encoding: "utf8" }
);

if (elmResult.error) {
    fail(`could not run \`elm\`: ${elmResult.error.message}`);
}

// elm writes plain "Success! ..." to stdout when everything compiles, and a
// JSON report to stderr only when there is something to report (compile
// errors, or a top-level config/parse problem).
let report = null;
const stderrTrimmed = (elmResult.stderr ?? "").trim();
if (stderrTrimmed.length > 0) {
    try {
        report = JSON.parse(stderrTrimmed);
    } catch (e) {
        fail(
            `could not parse elm's --report=json output as JSON.\n` +
                `--- elm stdout ---\n${elmResult.stdout}\n` +
                `--- elm stderr ---\n${elmResult.stderr}`
        );
    }
}

if (report && report.type !== "compile-errors") {
    // e.g. a top-level "error" (bad elm.json, missing package, etc.) — not a
    // per-file compile-errors report, so we can't attribute it to a fixture.
    fail(
        `elm reported a non-compile-errors problem (type: ${report.type}). ` +
            `This usually means the temp project itself is broken, not the fixtures.\n` +
            JSON.stringify(report, null, 2)
    );
}

// Map absolute fixture path -> list of error headers (e.g. ["TYPE MISMATCH"]).
// A fixture with no entry compiled cleanly.
const headersByPath = new Map();
if (report) {
    for (const err of report.errors) {
        const titles = err.problems.map((p) => p.title);
        headersByPath.set(resolve(err.path), titles);
    }
}

// --- 3. Score each fixture against the manifest -----------------------------

function messageText(problem) {
    return problem.message
        .map((part) => (typeof part === "string" ? part : part.string ?? ""))
        .join("");
}

const rows = [];
let anyFailure = false;

for (const file of rejectFiles) {
    const relPath = relative(SCRIPT_DIR, file);
    const expected = manifest[relPath];
    const gotHeaders = headersByPath.get(resolve(file));

    if (!gotHeaders) {
        anyFailure = true;
        rows.push({
            fixture: relPath,
            expected: expected.join(" | "),
            got: "(compiled successfully)",
            pass: "FAIL",
        });
        continue;
    }

    const matched = gotHeaders.some((h) => expected.includes(h));
    if (!matched) {
        anyFailure = true;
    }
    rows.push({
        fixture: relPath,
        expected: expected.join(" | "),
        got: gotHeaders.join(" | "),
        pass: matched ? "pass" : "FAIL",
    });
}

for (const file of acceptFiles) {
    const relPath = relative(SCRIPT_DIR, file);
    const gotHeaders = headersByPath.get(resolve(file));
    const pass = gotHeaders === undefined;
    if (!pass) {
        anyFailure = true;
    }
    rows.push({
        fixture: relPath,
        expected: "(compiles)",
        got: gotHeaders ? gotHeaders.join(" | ") : "(compiled successfully)",
        pass: pass ? "pass" : "FAIL",
    });
}

// --- 4. Print the table and any failing detail ------------------------------

const widths = {
    fixture: Math.max(7, ...rows.map((r) => r.fixture.length)),
    expected: Math.max(8, ...rows.map((r) => r.expected.length)),
    got: Math.max(3, ...rows.map((r) => r.got.length)),
    pass: 4,
};

function printRow(fixture, expected, got, pass) {
    console.log(
        `${fixture.padEnd(widths.fixture)}  ${expected.padEnd(widths.expected)}  ${got.padEnd(
            widths.got
        )}  ${pass}`
    );
}

console.log();
printRow("fixture", "expected", "got", "pass");
printRow("-".repeat(widths.fixture), "-".repeat(widths.expected), "-".repeat(widths.got), "----");
for (const r of rows) {
    printRow(r.fixture, r.expected, r.got, r.pass);
}
console.log();

if (anyFailure) {
    console.log("Failing fixtures in detail:");
    console.log();
    for (const file of allFiles) {
        const relPath = relative(SCRIPT_DIR, file);
        const row = rows.find((r) => r.fixture === relPath);
        if (row && row.pass === "FAIL" && report) {
            const err = report.errors.find((e) => resolve(e.path) === resolve(file));
            if (err) {
                console.log(`=== ${relPath} ===`);
                for (const problem of err.problems) {
                    console.log(`[${problem.title}]`);
                    console.log(messageText(problem));
                    console.log();
                }
            }
        }
    }
}

rmSync(tempDir, { recursive: true, force: true });

if (anyFailure) {
    console.error(`should-not-compile: ${rows.filter((r) => r.pass === "FAIL").length} fixture(s) failed.`);
    process.exit(1);
}

console.log(`should-not-compile: all ${rows.length} fixtures behaved as expected.`);
