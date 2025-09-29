// js/components/code-editor-view.js
import { handleFetchResponse } from '#melezh_base_path#js/error-fetch.js';

export const codeEditorView = () => ({
  code: '',
  fileName: null,
  isDirty: false,
  isSaving: false,
  saved: false,
  error: '',
  isLoading: false,

  async init() {
    // Получаем имя файла из хеша URL: #code-editor?file=...
    const hash = window.location.hash;
    const match = hash.match(/[?&]file=([^&]*)/);
    this.fileName = match ? decodeURIComponent(match[1]) : null;

    if (!this.fileName) {
      this.error = 'Не указан файл для редактирования';
      return;
    }

    await this.loadCode();
  },

  async loadCode() {
    this.isLoading = true;
    this.error = '';

    try {
      // Можно использовать GET или POST — выбери то, что у тебя в API
      // Вариант 1: GET с query-параметром
      const url = `api/getText?file=${encodeURIComponent(this.fileName)}`;
      const response = await fetch(url);

      // Вариант 2: POST (раскомментируй, если нужно)
      /*
      const response = await fetch('api/getCode', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: new URLSearchParams({ file: this.fileName })
      });
      */

      if (!response.ok) throw new Error(`HTTP ${response.status}`);

      const data = await response.json();

      // Ожидаем формат: { result: true, text: "..." }
      if (!data.result) {
        throw new Error(data.error || 'Сервер вернул ошибку');
      }

      this.code = data.text || '';
      this.isDirty = false;
      this.saved = false;

      this.$nextTick(() => this.updateHighlight());

    } catch (err) {
      console.error('Ошибка загрузки кода:', err);
      this.error = `Ошибка загрузки: ${err.message}`;
      window.dispatchEvent(new CustomEvent('show-error', {
        detail: { message: this.error }
      }));
    } finally {
      this.isLoading = false;
    }
  },

  onInput() {
    const text = this.getPlainTextFromEditor();
    this.code = text;
    this.isDirty = true;
    this.saved = false;
    this.error = '';
    this.updateHighlight();
  },

  getPlainTextFromEditor() {
    const el = this.$refs.editor;
    const clone = el.cloneNode(true);
    clone.querySelectorAll('span').forEach(span => {
      span.replaceWith(...span.childNodes);
    });
    return clone.textContent || '';
  },

  updateHighlight() {
    const editor = this.$refs.editor;
    editor.innerHTML = `<code class="language-bsl">${Prism.util.encode(this.code)}</code>`;
    Prism.highlightElement(editor.querySelector('code'));
  },

  handleTab(e) {
    if (e.key === 'Tab') {
      e.preventDefault();
      const sel = window.getSelection();
      if (sel.rangeCount > 0) {
        const range = sel.getRangeAt(0);
        const tabNode = document.createTextNode('  ');
        range.deleteContents();
        range.insertNode(tabNode);
        range.setStartAfter(tabNode);
        range.setEndAfter(tabNode);
        sel.removeAllRanges();
        sel.addRange(range);
        this.onInput();
      }
    }
  },

  async save() {
    if (!this.isDirty || !this.fileName) return;

    this.isSaving = true;
    this.error = '';

    try {
      const response = await fetch('api/saveCode', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          file: this.fileName,
          code: this.code
        })
      });

      const result = await handleFetchResponse(response);
      if (!result.success) throw new Error(result.message);

      this.isDirty = false;
      this.saved = true;
      setTimeout(() => this.saved = false, 2000);

      window.dispatchEvent(new CustomEvent('show-success', {
        detail: { message: 'Код успешно сохранён' }
      }));

    } catch (err) {
      console.error('Ошибка сохранения:', err);
      this.error = `Ошибка: ${err.message}`;
      window.dispatchEvent(new CustomEvent('show-error', {
        detail: { message: this.error }
      }));
    } finally {
      this.isSaving = false;
    }
  }
});