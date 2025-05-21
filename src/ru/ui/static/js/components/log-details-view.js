import { handleFetchResponse } from '/js/error-fetch.js';
import { jsonViewer } from '/js/json-viewer.js';

export const logDetailsView = () => ({
  isLoading: true,
  eventData: null,
  errorMessage: '',
  hasFiles() {
    return Array.isArray(this.eventData?.melezh_request_files) && this.eventData.melezh_request_files.length > 0;
  },
  async init() {
    this.isLoading = true;
    this.errorMessage = '';
    const urlParams = new URLSearchParams(window.location.hash.split('?')[1] || '');
    const key = urlParams.get('key');

    if (!key) {
      this.errorMessage = 'Не указан ключ события';
      this.isLoading = false;
      return;
    }

    try {
      const response = await fetch(`/api/getEventData?key=${encodeURIComponent(key)}`);
      const result = await handleFetchResponse(response);

      if (!result.success) throw new Error(result.message);
      this.eventData = result.data;
    } catch (error) {
      window.dispatchEvent(new CustomEvent('show-error', {
        detail: { message: `Ошибка загрузки: ${error.message}` }
      }));
      this.errorMessage = error.message;
    } finally {
      this.isLoading = false;
    }
  },
  getStatusText(status) {
    if (status >= 200 && status < 300) return 'Успех';
    if (status >= 400 && status < 500) return 'Клиентская ошибка';
    if (status >= 500) return 'Ошибка сервера';
    return 'Неизвестный статус';
  },
  // Метод для отрисовки JSON
  renderJson(value) {
    return jsonViewer.renderValue(value, 0);
  },
});