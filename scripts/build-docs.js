import { spawnSync } from 'node:child_process';
import {
	mkdirSync,
	readFileSync,
	writeFileSync,
} from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = dirname(dirname(fileURLToPath(import.meta.url)));
const source = join(root, 'docs', 'niori.texi');
const build = join(root, 'docs', 'build');
const htmlOutput = join(build, 'niori.html');
const infoOutput = join(build, 'niori.info');
const includeOutput = join(
	root,
	'_source',
	'_includes',
	'niori-manual.html',
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

console.log('Generated Niori HTML and Info manuals.');
