import { handleFetchResponse } from '/js/error-fetch.js';
import { globalState } from '/js/components/app.js';

// ВНЕ функции logsView — храним состояние между пересозданиями
const cachedState = {
  handler: '',
  date: '',
};

export const logsView = () => ({
  // Состояние
  handler: cachedState.handler,
  date: cachedState.date,
  filtersCollapsed: false,
  isEventsLoading: false,
  isEventsLoaded: false,
  events: [],
  eventsErrorMessage: '',

  // Вычисляемое свойство
  get hasFilters() {
    return this.handler.trim() !== '' && this.date.trim() !== '';
  },

  toggleFilters() {
    this.filtersCollapsed = !this.filtersCollapsed;
  },

  // Инициализация
  init() {
    const parseHash = () => {
      const urlParams = new URLSearchParams(window.location.hash.split('?')[1] || '');
      const handler = urlParams.get('handler') || cachedState.handler || '';
      const date = urlParams.get('date') || cachedState.date || '';

      this.handler = handler;
      this.date = date;

      cachedState.handler = handler;
      cachedState.date = date;
    };

    parseHash();

    // Загружаем события только один раз
    if (!globalState.isInitialized) {
      globalState.isInitialized = true;
      this.loadEvents();
    }
  },

  async loadEvents() {
    if (!this.hasFilters) return;

    const newHash = `#logs?handler=${encodeURIComponent(this.handler)}&date=${encodeURIComponent(this.date)}`;
    if (window.location.hash !== newHash) {
      window.history.pushState(null, '', newHash);
    }

    this.isEventsLoading = true;
    this.eventsErrorMessage = '';

    try {
      const url = `/api/getEvents?handler=${encodeURIComponent(this.handler)}&date=${encodeURIComponent(this.date)}`;
      const response = await fetch(url);
      const result = await handleFetchResponse(response);

      if (!result.success) throw new Error(result.message);

      this.events = result.data || [];
    } catch (error) {
      console.error('Ошибка загрузки логов:', error);
      this.eventsErrorMessage = error.message;
    } finally {
      this.isEventsLoaded = true;
      this.isEventsLoading = false;
      cachedState.handler = this.handler;
      cachedState.date = this.date;
    }
  },

  getStatusText(status) {
    if (status >= 200 && status < 300) return 'Успех';
    if (status >= 400 && status < 500) return 'Клиентская ошибка';
    if (status >= 500) return 'Ошибка сервера';
    return 'Неизвестный статус';
  },

  showDetails(event) {
    alert('Пока не реализовано');
  },
});