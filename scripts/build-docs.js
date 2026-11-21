
import { spawnSync } from 'node:child_process';
import {
    copyFileSync,
    existsSync,
    mkdirSync,
    readFileSync,
    readdirSync,
    writeFileSync,
} from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = dirname(dirname(fileURLToPath(import.meta.url)));

const docs = join(root, 'docs');
const build = join(docs, 'build');
const source = join(docs, 'niori.texi');

const htmlOutput = join(build, 'niori.html');
const infoOutput = join(build, 'niori.info');
const pdfOutput = join(build, 'niori.pdf');

const pdfScript = join(root, 'scripts', 'texi2styledpdf.sh');

const includeOutput = join(
    root,
    '_source',
    '_includes',
    'niori-manual.html',
);

const downloads = join(
    root,
    '_source',
    'assets',
    'downloads',
    'documentation',
);

function runMakeinfo(args, format) {
    const result = spawnSync('makeinfo', args, {
        cwd: root,
        encoding: 'utf8',
        maxBuffer: 16 * 1024 * 1024,
    });

    if (result.error) {
        throw result.error;
    }

    if (result.status !== 0) {
        throw new Error(
            `${format} generation failed:\n${result.stderr || result.stdout}`,
        );
    }

    if (result.stderr.trim()) {
        process.stderr.write(result.stderr);
    }
}

function runPdfScript() {
    const result = spawnSync(pdfScript, [source], {
        cwd: build,
        encoding: 'utf8',
        maxBuffer: 16 * 1024 * 1024,
    });

    if (result.error) {
        throw result.error;
    }

    if (result.stdout) {
        process.stdout.write(result.stdout);
    }

    if (result.stderr) {
        process.stderr.write(result.stderr);
    }

    if (result.status !== 0) {
        throw new Error('Niori PDF generation failed.');
    }

    if (!existsSync(pdfOutput)) {
        throw new Error(
            `PDF script completed but did not produce ${pdfOutput}`,
        );
    }
}

function copyPdfTree(sourceDir, destinationDir) {
    if (!existsSync(sourceDir)) {
        return;
    }

    mkdirSync(destinationDir, { recursive: true });

    for (const entry of readdirSync(sourceDir, {
        withFileTypes: true,
    })) {
        const sourcePath = join(sourceDir, entry.name);
        const destinationPath = join(destinationDir, entry.name);

        if (entry.isDirectory()) {
            copyPdfTree(sourcePath, destinationPath);
        } else if (entry.isFile() && /\.pdf$/i.test(entry.name)) {
            copyFileSync(sourcePath, destinationPath);
        }
    }
}

mkdirSync(build, { recursive: true });
mkdirSync(dirname(includeOutput), { recursive: true });

runMakeinfo(
    ['--html', '--no-split', `--output=${htmlOutput}`, source],
    'HTML',
);

const html = readFileSync(htmlOutput, 'utf8');
const body = html.match(/<body\b[^>]*>([\s\S]*?)<\/body>/i);

if (!body) {
    throw new Error('Could not extract the HTML body from Texinfo output.');
}

writeFileSync(includeOutput, `${body[1].trim()}\n`, 'utf8');

runMakeinfo(
    ['--info', '--no-split', `--output=${infoOutput}`, source],
    'Info',
);

runPdfScript();

const nioriDownloads = join(downloads, 'niori');
mkdirSync(nioriDownloads, { recursive: true });

copyFileSync(
    pdfOutput,
    join(nioriDownloads, 'niori-manual.pdf'),
);

copyFileSync(
    join(docs, 'niori-cheat-sheet.pdf'),
    join(nioriDownloads, 'niori-cheat-sheet.pdf'),
);

copyPdfTree(
    join(docs, 'pdf'),
    join(downloads, 'pdf'),
);

console.log('Generated Niori HTML, Info, and PDF manuals.');

