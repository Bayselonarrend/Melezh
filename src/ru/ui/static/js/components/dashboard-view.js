import { handleFetchResponse } from '/js/error-fetch.js';

export const dashboardView = () => ({
  isEventsLoading: false,
  events: [],
  eventsErrorMessage: '',

  // Новые поля для статистики
  successCount: 0,
  clientErrorCount: 0,
  serverErrorCount: 0,

  // Новые поля для сессии
  isSessionLoading: false,
  sessionErrorMessage: '',
  serverStartTime: null,
  processedRequests: 0,
  uptime: '—',
  requestsPerHour: 0,
  uptimeInterval: null,

  isAdviceLoading: true,
  advice: null,
  adviceErrorMessage: '',

  async init() {
    await this.loadEvents();
    await this.loadSessionInfo();
    await this.loadRandomAdvice();
  },

  async loadEvents() {
    this.isEventsLoading = true;
    this.eventsErrorMessage = '';

    try {
      const response = await fetch('/api/getLastEvents');
      const result = await handleFetchResponse(response);

      if (!result.success) throw new Error(result.message);

      this.events = result.data || [];

      // Подсчёт статистики
      this.calculateStats();

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

  async loadSessionInfo() {
    this.isSessionLoading = true;
    this.sessionErrorMessage = '';
    this.serverStartTime = null;

    try {
      const response = await fetch('/api/getSessionInfo');
      const result = await handleFetchResponse(response);

      if (!result.success) throw new Error(result.error || result.message);

      const { start, processed } = result.data;

      this.serverStartTime = new Date(start);
      this.processedRequests = processed;

      this.updateUptime(); // начальное значение
      this.uptimeInterval = setInterval(() => this.updateUptime(), 1000); // обновление каждую секунду

      // Среднее за час
      const now = new Date();
      const hoursRunning = Math.max(0.1, (now - this.serverStartTime) / 1000 / 60 / 60); // избежание деления на 0
      this.requestsPerHour = Math.round(this.processedRequests / hoursRunning);

    } catch (error) {
      console.error('Ошибка загрузки информации о сессии:', error);
      window.dispatchEvent(new CustomEvent('show-error', {
        detail: { message: `Ошибка загрузки информации о сессии: ${error.message}` }
      }));
      this.sessionErrorMessage = error.message;
    } finally {
      this.isSessionLoading = false;
    }
  },

  updateUptime() {
    if (!this.serverStartTime) return;

    const diff = Math.floor((new Date() - new Date(this.serverStartTime)) / 1000); // в секундах
    const days = Math.floor(diff / 86400);
    const hours = Math.floor((diff % 86400) / 3600);
    const minutes = Math.floor((diff % 3600) / 60);
    const seconds = diff % 60;

    let uptimeStr = '';
    if (days > 0) uptimeStr += `${days} д `;
    if (hours > 0) uptimeStr += `${hours} ч `;
    if (minutes > 0) uptimeStr += `${minutes} мин `;
    if (seconds >= 0 && !days && !hours) uptimeStr += `${seconds} с`;

    this.uptime = uptimeStr.trim() || 'меньше секунды';
  },

  calculateStats() {
    const counts = {
      success: 0,
      clientError: 0,
      serverError: 0,
    };

    for (const event of this.events) {
      if (event.status >= 200 && event.status < 300) {
        counts.success++;
      } else if (event.status >= 400 && event.status < 500) {
        counts.clientError++;
      } else if (event.status >= 500) {
        counts.serverError++;
      }
    }

    this.successCount = counts.success;
    this.clientErrorCount = counts.clientError;
    this.serverErrorCount = counts.serverError;
  },

  getStatusText(status) {
    if (status >= 200 && status < 300) return 'Успех';
    if (status >= 400 && status < 500) return 'Клиентская ошибка';
    if (status >= 500) return 'Ошибка сервера';
    return 'Неизвестный статус';
  },

  async loadRandomAdvice() {
    try {
      const response = await fetch('/api/getRandomAdvice');
      const result = await handleFetchResponse(response);

      if (!result.success) throw new Error(result.error || result.message);

      this.advice = result.data;
      this.adviceErrorMessage = '';
    } catch (error) {
      console.error('Ошибка загрузки совета:', error);
      window.dispatchEvent(new CustomEvent('show-error', {
        detail: { message: `Не удалось загрузить совет: ${error.message}` }
      }));
      this.adviceErrorMessage = error.message;
      this.advice = null;
    } finally {
      this.isAdviceLoading = false;
    }
  },

  async refreshData() {
    await Promise.all([
      this.loadEvents(),
      this.loadSessionInfo(),
      this.loadRandomAdvice(), // если совет реализован как часть dashboardView
    ]);
  }

});