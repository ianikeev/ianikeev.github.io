/* ----------------------------------------------------------------------------
switch between color themes and display modes
---------------------------------------------------------------------------- */
export default class ThemePicker extends HTMLElement {
	constructor() {
		super();
		this.buttons = [];
		this.handleClick = this.handleClick.bind(this);
		this.currentTheme = null;
		this.currentMode = null;
	}

	saveValue(type, value) {
		window.localStorage.setItem(type, value);
		this.updateButtons(type, value);
		this.applyValues();
	}

	applyValues() {
		const availableThemes = [
			'modus',
			'modus-tinted',
			'ef-elea',
			'ef-maris',
			'ef-trio',
		];

		const savedTheme = window.localStorage.getItem('theme');
		const theme = availableThemes.includes(savedTheme) ? savedTheme : 'modus';
		const savedMode = window.localStorage.getItem('mode');
		const mode = ['system', 'dark', 'light'].includes(savedMode)
			? savedMode
			: 'system';

		if (this.currentTheme && this.currentTheme !== 'default') {
			this.target.classList.remove(this.currentTheme);
		}

		if (this.currentMode && this.currentMode !== 'system') {
			this.target.classList.remove(this.currentMode);
		}

		this.target.classList.remove(
			'high-contrast',
			'low-contrast',
			'primary',
			'secondary',
		);

		this.target.classList.add(theme);

		if (mode !== 'system') {
			this.target.classList.add(mode);
		}

		if (savedTheme !== theme) {
			window.localStorage.setItem('theme', theme);
		}

		if (savedMode !== mode) {
			window.localStorage.setItem('mode', mode);
		}

		this.currentTheme = theme;
		this.currentMode = mode;
	}

	updateButtons(type, value) {
		const currentActive = this.querySelector(
			`[data-type="${type}"][aria-current="true"]`,
		);
		if (currentActive) {
			currentActive.removeAttribute('aria-current');
		}

		const newActive = this.querySelector(
			`[data-type="${type}"][data-value="${value}"]`,
		);
		if (newActive) {
			newActive.setAttribute('aria-current', 'true');
		}
	}

	handleClick(e) {
		const button = e.currentTarget;
		const type = button.getAttribute('data-type');
		const value = button.getAttribute('data-value');
		this.saveValue(type, value);
	}

	setupControls() {
		this.buttons = Array.from(this.querySelectorAll('[data-type][data-value]'));
		for (const element of this.buttons) {
			element.addEventListener('click', this.handleClick);
		}
	}

	connectedCallback() {
		this.target = document.documentElement;
		this.currentTheme = window.localStorage.getItem('theme') || 'default';
		this.currentMode = window.localStorage.getItem('mode') || 'system';
		this.applyValues();
		this.updateButtons('theme', this.currentTheme);
		this.updateButtons('mode', this.currentMode);
		this.setupControls();
	}

	disconnectedCallback() {
		if (this.buttons.length > 0) {
			for (const element of this.buttons) {
				element.removeEventListener('click', this.handleClick);
			}
		}
	}
}

window.customElements.define('theme-picker', ThemePicker);
