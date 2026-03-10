/**
 * Convertit les règles du repo cursor.directory (fichiers .ts dans src/data/rules/)
 * en fichiers .mdc pour .cursor/rules/
 * Usage: node convert-directory-rules.cjs <repoDir> <outputDir>
 */

const fs = require('fs');
const path = require('path');

const repoDir = process.argv[2];
const outputDir = process.argv[3];

if (!repoDir || !outputDir) {
  console.error('Usage: node convert-directory-rules.cjs <repoDir> <outputDir>');
  process.exit(1);
}

const rulesDir = path.join(repoDir, 'src', 'data', 'rules');
if (!fs.existsSync(rulesDir)) {
  console.error('Dossier rules introuvable:', rulesDir);
  process.exit(1);
}

if (!fs.existsSync(outputDir)) {
  fs.mkdirSync(outputDir, { recursive: true });
}

/**
 * Extrait title, slug, content (et optionnellement tags) d'un fichier .ts
 * Format attendu: export const X = { title: "...", slug: "...", content: `...`, ... }
 */
function extractRuleFromTs(filePath) {
  const raw = fs.readFileSync(filePath, 'utf8');
  const titleMatch = raw.match(/title:\s*["']([^"']+)["']/);
  const slugMatch = raw.match(/slug:\s*["']([^"']+)["']/);
  // content peut être en backticks (template literal) ou string
  let content = null;
  const contentStart = raw.indexOf('content:');
  if (contentStart !== -1) {
    const afterLabel = raw.slice(contentStart + 8);
    const tick = afterLabel.indexOf('`');
    if (tick === 0 || (tick > 0 && /^\s*`/.test(afterLabel))) {
      const start = afterLabel.indexOf('`') + 1;
      let end = start;
      for (; end < afterLabel.length; end++) {
        if (afterLabel[end] === '`' && afterLabel[end - 1] !== '\\') break;
      }
      content = afterLabel.slice(start, end).trim();
    } else {
      const doubleMatch = afterLabel.match(/^\s*"((?:[^"\\]|\\.)*)"/s);
      if (doubleMatch) content = doubleMatch[1].replace(/\\"/g, '"').trim();
    }
  }
  const title = titleMatch ? titleMatch[1] : path.basename(filePath, '.ts');
  const slug = slugMatch ? slugMatch[1] : path.basename(filePath, '.ts').replace(/\s+/g, '-');
  return { title, slug, content: content || '' };
}

let count = 0;
const files = fs.readdirSync(rulesDir).filter((f) => f.endsWith('.ts'));

for (const file of files) {
  const filePath = path.join(rulesDir, file);
  if (!fs.statSync(filePath).isFile()) continue;
  const { title, slug, content } = extractRuleFromTs(filePath);
  const safeName = (slug || path.basename(file, '.ts')).replace(/[^\w-]/g, '-') + '.mdc';
  const description = title || safeName.replace('.mdc', '');
  const frontmatter = `---
description: ${JSON.stringify(description)}
alwaysApply: false
---

`;
  const body = content ? `# ${title}\n\n${content}` : `# ${title}\n\n(Règle importée depuis cursor.directory – contenu à compléter.)\n`;
  const outPath = path.join(outputDir, safeName);
  fs.writeFileSync(outPath, frontmatter + body, 'utf8');
  console.log('  ', safeName);
  count++;
}

console.log('');
console.log(count + ' règle(s) convertie(s) vers', outputDir);
