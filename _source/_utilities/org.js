
import { spawnSync } from 'node:child_process';
import {
        mkdtempSync,
        writeFileSync,
        rmSync,
} from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const exporter = `
(progn
  (require 'ox-html)
  (let ((org-export-with-toc nil)
        (org-export-with-section-numbers nil))
    (with-temp-buffer
      (insert-file-contents (getenv "ORG_INPUT_FILE"))
      (princ (org-export-string-as (buffer-string) 'html t)))))
`;

export default function orgToHtml(source) {
        const directory = mkdtempSync(join(tmpdir(), 'eleventy-org-'));
        const inputFile = join(directory, 'input.org');

        try {
                writeFileSync(inputFile, source, 'utf8');

                const result = spawnSync(
                        'emacs',
                        ['-Q', '--batch', '--eval', exporter],
                        {
                                encoding: 'utf8',
                                env: {
                                        ...process.env,
                                        ORG_INPUT_FILE: inputFile,
                                },
                                maxBuffer: 16 * 1024 * 1024,
                        },
                );

                if (result.error) {
                        throw result.error;
                }

                if (result.status !== 0) {
                        throw new Error(`Org export failed:\n${result.stderr}`);
                }

                return result.stdout;
        } finally {
                rmSync(directory, { recursive: true, force: true });
        }
}

