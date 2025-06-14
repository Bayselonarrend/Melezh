import { handleFetchResponse } from '#melezh_base_path#js/error-fetch.js';
import { globalState, logsState } from '#melezh_base_path#js/components/app.js';

export const logsView = () => ({

  handler: logsState.handler,
  date: logsState.date,
  filtersCollapsed: false,
  isEventsLoading: false,
  isEventsLoaded: false,
  events: [],
  eventsErrorMessage: '',

  get hasFilters() {
    return this.handler.trim() !== '' && this.date.trim() !== '';
  },

  toggleFilters() {
    this.filtersCollapsed = !this.filtersCollapsed;
  },

  init() {

    const urlParams = new URLSearchParams(window.location.hash.split('?')[1] || '');
    logsState.handler = urlParams.get('handler') || logsState.handler || '';
    logsState.date = urlParams.get('date') || logsState.date || '';

    this.$nextTick(() => {
      this.handler = logsState.handler;
      this.date = logsState.date;

      if (!globalState.isInitialized) {
        globalState.isInitialized = true;
        this.loadEvents();
      }
    });
  },

  async loadEvents() {

    if (!this.handler.trim() || !this.date.trim()) return;

    const focusedElement = document.activeElement;

    const newHash = `#logs?handler=${encodeURIComponent(this.handler)}&date=${encodeURIComponent(this.date)}`;
    if (window.location.hash !== newHash) {
      window.history.pushState(null, '', newHash);
    }

    logsState.handler = this.handler;
    logsState.date = this.date;

    this.isEventsLoading = true;

    try {
      const url = `api/getEvents?handler=${encodeURIComponent(this.handler)}&date=${encodeURIComponent(this.date)}`;
      const response = await fetch(url);
      const result = await handleFetchResponse(response);

      this.events = result.data || [];
      this.eventsErrorMessage = '';
    } catch (error) {
      this.eventsErrorMessage = error.message;
    } finally {
      this.isEventsLoading = false;
      this.isEventsLoaded = true;

      // Восстанавливаем фокус
      this.$nextTick(() => {
        if (focusedElement && focusedElement.tagName === 'INPUT') {
          focusedElement.focus();
        }
      });
    }
  },

  getStatusText(status) {
    if (status >= 200 && status < 300) return 'Успех';
    if (status >= 400 && status < 500) return 'Клиентская ошибка';
    if (status >= 500) return 'Ошибка сервера';
    return 'Неизвестный статус';
  },

});