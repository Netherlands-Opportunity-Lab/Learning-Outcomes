import { readdir, stat } from "node:fs/promises";
import { extname, join, relative } from "node:path";

const root = new URL("../", import.meta.url).pathname;
const forbiddenExtensions = new Set([
  ".sav",
  ".zsav",
  ".sas7bdat",
  ".dta",
  ".rds",
  ".rdata",
  ".zip",
  ".7z"
]);
const ignoredDirectories = new Set([".git", "node_modules", "dist", ".astro"]);
const violations = [];

async function walk(directory) {
  for (const entry of await readdir(directory, { withFileTypes: true })) {
    if (entry.isDirectory() && ignoredDirectories.has(entry.name)) continue;
    const absolute = join(directory, entry.name);
    const path = relative(root, absolute).replaceAll("\\", "/");
    if (entry.isDirectory()) {
      await walk(absolute);
      continue;
    }
    const info = await stat(absolute);
    if (info.size > 25 * 1024 * 1024) violations.push(`${path}: exceeds 25 MiB`);
    if (forbiddenExtensions.has(extname(entry.name).toLowerCase())) {
      violations.push(`${path}: forbidden research-data/archive extension`);
    }
    if (path.startsWith("data-raw/") && path !== "data-raw/README.md") {
      violations.push(`${path}: raw data must not be committed`);
    }
    if (path.startsWith("data-derived/") && path !== "data-derived/.gitkeep") {
      violations.push(`${path}: derived working data must not be committed`);
    }
  }
}

await walk(root);
if (violations.length > 0) {
  console.error(violations.join("\n"));
  process.exit(1);
}
console.log("Repository boundary check passed.");
