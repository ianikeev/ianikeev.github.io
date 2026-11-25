import { spawnSync } from 'node:child_process';
import {
	copyFileSync,
	existsSync,
	mkdirSync,
	readFileSync,
	readdirSync,
	rmSync,
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
const nioriPdfSource = join(docs, 'niori-pdf.texi');
const nioriPdfBuild = join(build, 'niori-pdf');
const nioriPdfHtml = join(nioriPdfBuild, 'html');
const nioriPdfPages = join(
        root,
        '_source',
        'documentation',
        'niori-pdf',
);
const nioriPdfOutput = join(nioriPdfBuild, 'niori-pdf.pdf');

const pdfScript = join(root, 'scripts', 'texi2styledpdf.sh');

const includeOutput = join(root, '_source', '_includes', 'niori-manual.html');

const downloads = join(root, '_source', 'assets', 'downloads', 'documentation');

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

function runPdfScript(sourceFile, workingDirectory, outputFile, manualName) {
	const result = spawnSync(pdfScript, [sourceFile], {
		cwd: workingDirectory,
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
		throw new Error(`${manualName} PDF generation failed.`);
	}

	if (!existsSync(outputFile)) {
		throw new Error(
			`PDF script completed but did not produce ${outputFile}`,
		);
	}
}

function generateNioriPdfPages() {
        rmSync(nioriPdfPages, { recursive: true, force: true });
        mkdirSync(nioriPdfPages, { recursive: true });

        for (const filename of readdirSync(nioriPdfHtml)) {
                if (!filename.endsWith('.html')) {
                        continue;
                }

                const html = readFileSync(
                        join(nioriPdfHtml, filename),
                        'utf8',
                );

                const title = html.match(/<title>(.*?)<\/title>/s)?.[1];
                const body = html.match(/<body[^>]*>([\s\S]*?)<\/body>/i)?.[1];

                if (!title || !body) {
                        throw new Error(
                                `Could not extract title or body from ${filename}`,
                        );
                }

                const pageTitle = title.replace(
                        /\s*\(niori-pdf:.*$/,
                        '',
                );

                const permalink =
                        filename === 'index.html'
                                ? '/documentation/niori-pdf/'
                                : `/documentation/niori-pdf/${filename}`;

                const page = [
                        '---',
			`title: ${JSON.stringify(pageTitle)}`,
                        'description: Documentation for niori-pdf, PDF generation in pure Emacs Lisp.',
                        'layout: base.html',
                        `permalink: ${permalink}`,
                        '---',
                        '',
                        '<main class="grid">',
                        '    <article class="line-length-lg texinfo-manual">',
                        body.trim(),
                        '    </article>',
                        '</main>',
                        '',
                ].join('\n');

                writeFileSync(join(nioriPdfPages, filename), page);
        }

        console.log('Generated niori-pdf Eleventy pages.');
}

function buildNioriPdf() {
        rmSync(nioriPdfHtml, { recursive: true, force: true });
	mkdirSync(nioriPdfHtml, { recursive: true });

	runMakeinfo(
		[
			'--html',
			'--split=chapter',
			`--output=${nioriPdfHtml}/`,
			nioriPdfSource,
		],
		'niori-pdf HTML',
	);

	generateNioriPdfPages();

	runPdfScript(
		nioriPdfSource,
		nioriPdfBuild,
		nioriPdfOutput,
		'niori-pdf',
	);

	const pdfDestination = join(
		downloads,
		'niori-pdf',
		'niori-pdf-manual.pdf',
	);

	mkdirSync(dirname(pdfDestination), { recursive: true });
	copyFileSync(nioriPdfOutput, pdfDestination);

	console.log('Generated niori-pdf HTML and PDF manuals.');
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

function escapeHtml(value) {
	return value
		.replaceAll('&', '&amp;')
		.replaceAll('<', '&lt;')
		.replaceAll('>', '&gt;')
		.replaceAll('"', '&quot;')
		.replaceAll("'", '&#39;');
}

function collectPdfFiles(directory, relative = '') {
	if (!existsSync(directory)) {
		return [];
	}

	const files = [];

	for (const entry of readdirSync(directory, {
		withFileTypes: true,
	})) {
		const relativePath = join(relative, entry.name);
		const fullPath = join(directory, entry.name);

		if (entry.isDirectory()) {
			files.push(...collectPdfFiles(fullPath, relativePath));
		} else if (entry.isFile() && /\.pdf$/i.test(entry.name)) {
			files.push(relativePath);
		}
	}

	return files.sort((a, b) => a.localeCompare(b));
}

function generateOtherDocumentsInclude() {
	const sourceDir = join(docs, 'pdf');
	const includeDir = join(root, '_source', '_includes');
	const includeFile = join(includeDir, 'other-documents.html');

	mkdirSync(includeDir, { recursive: true });

	const files = collectPdfFiles(sourceDir);

	let output;

	if (files.length === 0) {
		output = '<p>No additional documents are currently available.</p>\n';
	} else {
		output = '<ul>\n';

		for (const file of files) {
			const urlPath = file.split(/[\\/]/).map(encodeURIComponent).join('/');

			output += `  <li><a href="/assets/downloads/documentation/pdf/${urlPath}">${escapeHtml(file)}</a></li>\n`;
		}

		output += '</ul>\n';
	}

	writeFileSync(includeFile, output, 'utf8');
}

mkdirSync(build, { recursive: true });
mkdirSync(dirname(includeOutput), { recursive: true });

runMakeinfo(['--html', '--no-split', `--output=${htmlOutput}`, source], 'HTML');

const html = readFileSync(htmlOutput, 'utf8');
const body = html.match(/<body\b[^>]*>([\s\S]*?)<\/body>/i);

if (!body) {
	throw new Error('Could not extract the HTML body from Texinfo output.');
}

writeFileSync(includeOutput, `${body[1].trim()}\n`, 'utf8');

const standaloneManual = join(
    root,
    '_source',
    'documentation',
    'niori',
    'index.html',
);

mkdirSync(dirname(standaloneManual), { recursive: true });

writeFileSync(
    standaloneManual,
    `---
title: Niori documentation
description: Documentation for the Niori medical information manager.
layout: base.html
permalink: /documentation/niori/
---

<main class="grid">
  <article class="line-length-lg niori-manual">
    {% include "niori-manual.html" %}
  </article>
</main>
`,
    'utf8',
);

generateOtherDocumentsInclude();

runMakeinfo(['--info', '--no-split', `--output=${infoOutput}`, source], 'Info');

runPdfScript(source, build, pdfOutput, 'Niori');

const nioriDownloads = join(downloads, 'niori');
mkdirSync(nioriDownloads, { recursive: true });

copyFileSync(pdfOutput, join(nioriDownloads, 'niori-manual.pdf'));

copyFileSync(
	join(docs, 'niori-cheat-sheet.pdf'),
	join(nioriDownloads, 'niori-cheat-sheet.pdf'),
);

copyPdfTree(join(docs, 'pdf'), join(downloads, 'pdf'));

buildNioriPdf();

console.log('Generated Niori and niori-pdf documentation.');
