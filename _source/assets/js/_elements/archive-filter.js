
/* ----------------------------------------------------------------------------
filter archive articles by tag
---------------------------------------------------------------------------- */
export default function ArchiveFilter() {
        const tags = document.querySelector('.js-tags');
        const result = document.querySelector('.js-result');

        if (!tags || !result) return;

        const decodeTag = (value) => {
                try {
                        return decodeURIComponent(value.replace(/\+/g, ' '));
                } catch {
                        return value;
                }
        };

        const buttons = [...tags.querySelectorAll('button')];
        const articles = [...result.querySelectorAll('.item')];
        const sections = [...result.querySelectorAll('section')];
        const showAll = tags.querySelector('.tag-button--all');

        function selectTag(tag, target = null) {
                articles.forEach((article) => {
                        const articleTags = (article.dataset.tags || '')
                                .split(',')
                                .filter(Boolean)
                                .map(decodeTag);

                        article.classList.toggle(
                                'hidden',
                                tag !== '' && !articleTags.includes(tag),
                        );
                });

                sections.forEach((section) => {
                        const visible = section.querySelector(
                                '.item:not(.hidden)',
                        );
                        section.classList.toggle('hidden', !visible);
                });

                result.classList.remove('hidden');

                const selectedButton =
                        target ||
                        buttons.find(
                                (button) =>
                                        decodeTag(button.dataset.encode || '') ===
                                        tag,
                        ) ||
                        showAll;

                buttons.forEach((button) => {
                        if (button === selectedButton) {
                                button.setAttribute('aria-current', 'true');
                        } else {
                                button.removeAttribute('aria-current');
                        }
                });

                const url = new URL(window.location);
                if (tag) {
                        url.searchParams.set('tag', tag);
                } else {
                        url.searchParams.delete('tag');
                }
                window.history.replaceState(null, '', url);
        }

        const initialTag =
                new URLSearchParams(window.location.search).get('tag') || '';

        const knownTag = buttons.some(
                (button) =>
                        decodeTag(button.dataset.encode || '') === initialTag,
        );

        selectTag(knownTag ? initialTag : '');

        tags.addEventListener('click', (event) => {
                const button = event.target.closest('button');
                if (!button || !tags.contains(button)) return;

                selectTag(decodeTag(button.dataset.encode || ''), button);
        });
}

