import markdownIt from 'markdown-it';
import orgToHtml from './_source/_utilities/org.js';
import esbuild from './_source/_utilities/esbuild.js';
import lightingcss from './_source/_utilities/lightningcss.js';
import image from './_source/_utilities/image.js';
import style from './_source/_utilities/style.js';
import setVar from './_source/_utilities/setVar.js';
import markdownify from './_source/_utilities/markdownify.js';
import { IdAttributePlugin } from '@11ty/eleventy';

export default async function (eleventyConfig) {
	/* --------------------------------------------------------------------------
  Plugins, bundles, shortcodes, filters
  -------------------------------------------------------------------------- */
	eleventyConfig.addPlugin(esbuild);
	eleventyConfig.addPlugin(lightingcss);
	eleventyConfig.addPlugin(IdAttributePlugin);
	eleventyConfig.addBundle('css', { transforms: [style] });
	eleventyConfig.addShortcode('image', image);
	eleventyConfig.addPairedShortcode('setVar', setVar);
	eleventyConfig.addFilter('markdownify', markdownify);

	/* --------------------------------------------------------------------------
  MarkdownIt settings
  -------------------------------------------------------------------------- */
	const markdownItOptions = {
		html: true,
		typographer: true,
	};
	eleventyConfig.setLibrary('md', markdownIt(markdownItOptions));

	/* --------------------------------------------------------------------------
  Files & folders
  -------------------------------------------------------------------------- */
	eleventyConfig.ignores.add('.DS_Store');
	eleventyConfig.setServerPassthroughCopyBehavior('passthrough');
	eleventyConfig.addPassthroughCopy('_source/assets/fonts');
	eleventyConfig.addPassthroughCopy('_source/assets/images');
	eleventyConfig.addPassthroughCopy('_source/CNAME');
	eleventyConfig.addPassthroughCopy('_source/site.webmanifest');
	eleventyConfig.addPassthroughCopy('_source/favicon.ico');

	/* --------------------------------------------------------------------------
	  Org-mode
	  -------------------------------------------------------------------------- */
	eleventyConfig.addExtension('org', {
		outputFileExtension: 'html',
		compile: function (inputContent) {
			const html = orgToHtml(inputContent);
			return async () => html;
		},
	});

	/* --------------------------------------------------------------------------
          Blog posts
          -------------------------------------------------------------------------- */
	eleventyConfig.addCollection('posts', (collectionApi) =>
		collectionApi
			.getAll()
			.filter((post) => post.inputPath.includes('/posts/'))
			.sort((a, b) => b.date - a.date),
	);

	eleventyConfig.addCollection('fiction', (collectionApi) => {
		return collectionApi
			.getAll()
			.filter((item) => item.inputPath.includes('/fiction/'))
			.sort((a, b) => a.data.title.localeCompare(b.data.title));
	});

	eleventyConfig.addCollection('archiveTags', (collectionApi) => {
		const counts = new Map();

		for (const post of collectionApi
			.getAll()
			.filter((post) => post.inputPath.includes('/posts/'))) {
			const tags = Array.isArray(post.data.tags)
				? post.data.tags
				: post.data.tags
					? [post.data.tags]
					: [];

			for (const tag of tags) {
				counts.set(tag, (counts.get(tag) || 0) + 1);
			}
		}

		return Array.from(counts, ([tag, count]) => ({ tag, count })).sort((a, b) =>
			a.tag.localeCompare(b.tag),
		);
	});

	eleventyConfig.addCollection('archiveYears', (collectionApi) => {
		const years = new Map();

		for (const post of collectionApi
			.getAll()
			.filter((post) => post.inputPath.includes('/posts/'))) {
			const year = post.date.getFullYear();

			if (!years.has(year)) {
				years.set(year, []);
			}

			years.get(year).push(post);
		}

		return Array.from(years, ([year, posts]) => ({
			year,
			posts: posts.sort((a, b) => b.date - a.date),
		})).sort((a, b) => b.year - a.year);
	});

	eleventyConfig.addGlobalData('env', {
		baseUrl: 'https://twoladsandacat.com',
		author: 'Igor Anikeev',
		language: 'en',
		timezone: 'America/Argentina/Buenos_Aires',
	});

	eleventyConfig.addGlobalData('eleventyComputed', {
		permalink: (data) => {
			if (data.page.inputPath.endsWith('/archive.html')) {
				return '/archive.html';
			}

			if (!data.page.inputPath.includes('/posts/')) {
				return data.permalink;
			}

			const date = data.date;
			const categories = data.categories;
			const category = Array.isArray(categories)
				? categories.join('/')
				: categories || '';
			const slug = data.page.fileSlug.replace(/^\d{4}-\d{2}-\d{2}-/, '');

			const year = date.getUTCFullYear();
			const month = String(date.getUTCMonth() + 1).padStart(2, '0');
			const day = String(date.getUTCDate()).padStart(2, '0');

			return `/${category ? `${category}/` : ''}${year}/${month}/${day}/${slug}.html`;
		},
	});

	return {
		dir: {
			input: '_source',
			output: '_public',
			layouts: '_layouts',
			includes: '_includes',
		},
		templateFormats: ['html', 'md', 'liquid', 'org'],
		htmlTemplateEngine: 'liquid',
	};
}
