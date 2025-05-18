import { handleFetchResponse } from '/js/error-fetch.js';

export const dashboardView = () => ({
  isEventsLoading: false,
  events: [],
  eventsErrorMessage: '',

  async init() {
    await this.loadEvents();
  },

  async loadEvents() {
    this.isEventsLoading = true;
    this.eventsErrorMessage = '';

    try {
      const response = await fetch('/api/getLastEvents');
      const result = await handleFetchResponse(response);

      if (!result.success) throw new Error(result.message);

      // Сохраняем события
      this.events = result.data || [];
    } catch (error) {
      console.error('Ошибка загрузки событий:', error);
      window.dispatchEvent(new CustomEvent('show-error', {
        detail: { message: `Ошибка загрузки событий: ${error.message}` }
      }));
      this.eventsErrorMessage = error.message;
    } finally {
      this.isEventsLoading = false;
    }
  },

  getStatusText(status) {
    if (status >= 200 && status < 300) return 'Успех';
    if (status >= 400 && status < 500) return 'Клиентская ошибка';
    if (status >= 500) return 'Ошибка сервера';
    return 'Неизвестный статус';
  }
});