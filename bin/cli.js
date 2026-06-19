#!/usr/bin/env node
'use strict';

// ppdevskill installer CLI — copies the skill into ~/.claude/skills/ and (opt-in)
// wires the VERIFIED-block Stop hook into ~/.claude/settings.json.
// No dependencies. Safety: backs up before overwriting; never clobbers unrelated
// settings keys; refuses to touch a settings.json it cannot parse.

const fs = require('fs');
const path = require('path');
const os = require('os');
const readline = require('readline');

const PKG_ROOT = path.resolve(__dirname, '..');
const pkg = require(path.join(PKG_ROOT, 'package.json'));
const ITEMS = ['SKILL.md', 'references', 'examples', 'hooks', 'README.md', 'LICENSE'];

const log = (m) => process.stdout.write(m + '\n');
const errln = (m) => process.stderr.write(m + '\n');

function defaultSkillDir() {
  return path.join(os.homedir(), '.claude', 'skills', 'ppdevskill');
}
function settingsPath() {
  return path.join(os.homedir(), '.claude', 'settings.json');
}
function stamp() {
  // Local timestamp for backup names (Node, not a workflow script — Date is fine).
  return new Date().toISOString().replace(/[:.]/g, '-');
}

function copyRecursive(src, dest) {
  const st = fs.statSync(src);
  if (st.isDirectory()) {
    fs.mkdirSync(dest, { recursive: true });
    for (const name of fs.readdirSync(src)) {
      if (name === '.DS_Store') continue;
      copyRecursive(path.join(src, name), path.join(dest, name));
    }
  } else {
    fs.mkdirSync(path.dirname(dest), { recursive: true });
    fs.copyFileSync(src, dest);
  }
}

function confirm(question) {
  return new Promise((resolve) => {
    const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
    rl.question(question, (a) => {
      rl.close();
      resolve(/^y(es)?$/i.test(String(a).trim()));
    });
  });
}

function printSnippet(cmdPath) {
  log('');
  log('To enable mechanical enforcement, merge this into ' + settingsPath() + ':');
  log('  (if a "hooks" key already exists, add the Stop entry — do not overwrite)');
  log('');
  log(JSON.stringify({
    hooks: { Stop: [{ matcher: '', hooks: [{ type: 'command', command: cmdPath }] }] }
  }, null, 2));
  log('');
}

// Returns {ok, changed, reason}. Preserves all existing keys; backs up first.
function wireHook(cmdPath) {
  const sp = settingsPath();
  let settings = {};
  if (fs.existsSync(sp)) {
    let raw;
    try { raw = fs.readFileSync(sp, 'utf8'); }
    catch (e) { return { ok: false, reason: 'cannot read settings.json (' + e.message + ')' }; }
    if (raw.trim()) {
      try { settings = JSON.parse(raw); }
      catch (e) { return { ok: false, reason: 'settings.json is not valid JSON — left untouched' }; }
    }
  }
  if (typeof settings !== 'object' || settings === null || Array.isArray(settings)) {
    return { ok: false, reason: 'settings.json root is not an object — left untouched' };
  }
  if (!settings.hooks || typeof settings.hooks !== 'object') settings.hooks = {};
  if (!Array.isArray(settings.hooks.Stop)) settings.hooks.Stop = [];

  const present = settings.hooks.Stop.some((entry) =>
    entry && Array.isArray(entry.hooks) &&
    entry.hooks.some((h) => h && typeof h.command === 'string' && h.command.includes('verify-guard.sh')));
  if (present) return { ok: true, changed: false };

  if (fs.existsSync(sp)) fs.copyFileSync(sp, sp + '.bak-' + stamp());
  settings.hooks.Stop.push({ matcher: '', hooks: [{ type: 'command', command: cmdPath }] });
  fs.mkdirSync(path.dirname(sp), { recursive: true });
  fs.writeFileSync(sp, JSON.stringify(settings, null, 2) + '\n');
  return { ok: true, changed: true };
}

async function install(opts) {
  const dest = opts.dir ? path.resolve(opts.dir) : defaultSkillDir();

  if (fs.existsSync(dest)) {
    const b = dest + '.bak-' + stamp();
    fs.renameSync(dest, b);
    log('Existing install moved aside -> ' + b);
  }
  fs.mkdirSync(dest, { recursive: true });
  for (const item of ITEMS) {
    const src = path.join(PKG_ROOT, item);
    if (fs.existsSync(src)) copyRecursive(src, path.join(dest, item));
  }

  const hooksDir = path.join(dest, 'hooks');
  if (fs.existsSync(hooksDir)) {
    for (const f of fs.readdirSync(hooksDir)) {
      if (f.endsWith('.sh')) fs.chmodSync(path.join(hooksDir, f), 0o755);
    }
  }
  log('Installed ppdevskill v' + pkg.version + ' -> ' + dest);

  const cmdPath = path.join(dest, 'hooks', 'verify-guard.sh');
  let doHook = opts.withHook;            // true | false | undefined
  if (doHook === undefined) {
    if (opts.yes) doHook = true;
    else if (process.stdin.isTTY) {
      doHook = await confirm('Wire the VERIFIED-block Stop hook into ' + settingsPath() + '? [y/N] ');
    } else {
      doHook = false;                    // non-interactive: never touch config silently
    }
  }

  if (doHook) {
    const r = wireHook(cmdPath);
    if (r.ok && r.changed) log('Stop hook wired into ' + settingsPath());
    else if (r.ok) log('Stop hook already present — settings.json unchanged.');
    else { errln('Could not wire hook: ' + r.reason); printSnippet(cmdPath); }
  } else {
    printSnippet(cmdPath);
  }

  log('Done. Restart Claude Code so the skill (and hook, if wired) load.');
}

function parseArgs(argv) {
  const opts = { _: [] };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--dir') opts.dir = argv[++i];
    else if (a === '--with-hook') opts.withHook = true;
    else if (a === '--no-hook') opts.withHook = false;
    else if (a === '--yes' || a === '-y') opts.yes = true;
    else if (a === '--version' || a === '-v') opts.version = true;
    else if (a === '--help' || a === '-h') opts.help = true;
    else opts._.push(a);
  }
  return opts;
}

const HELP = [
  'ppdevskill — engineering-partner skill for Claude Code',
  '',
  'Usage:',
  '  npx ppdevskill install [options]   Install into ~/.claude/skills/ppdevskill',
  '',
  'Options:',
  '  --dir <path>    Install to a custom directory',
  '  --with-hook     Wire the Stop hook into settings.json (no prompt)',
  '  --no-hook       Skip hook wiring; just print the snippet',
  '  -y, --yes       Assume yes to prompts',
  '  -v, --version   Print version',
  '  -h, --help      Show this help',
].join('\n');

async function main() {
  const opts = parseArgs(process.argv.slice(2));
  if (opts.version) { log(pkg.version); return; }
  if (opts.help) { log(HELP); return; }
  const cmd = opts._[0];
  if (cmd === 'install') { await install(opts); return; }
  if (!cmd) { log(HELP); return; }
  errln('Unknown command: ' + cmd);
  log(HELP);
  process.exitCode = 1;
}

main().catch((e) => { errln('ppdevskill: ' + (e && e.message ? e.message : e)); process.exitCode = 1; });
