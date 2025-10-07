import { handleFetchResponse } from '#melezh_base_path#js/error-fetch.js';

export const handlersView = () => ({
  handlers: [],
  isLoading: false,
  sortField: null,
  sortDirection: 'asc',

  init() {
    this.loadHandlers();
  },

  get sortedHandlers() {
    if (!this.sortField) return this.handlers;

    return [...this.handlers].sort((a, b) => {
      let aValue = a[this.sortField];
      let bValue = b[this.sortField];

      if (this.sortField === 'active') {
        aValue = aValue == 1 ? 1 : 0;
        bValue = bValue == 1 ? 1 : 0;
      }

      if (typeof aValue === 'string') aValue = aValue.toLowerCase();
      if (typeof bValue === 'string') bValue = bValue.toLowerCase();

      if (aValue < bValue) return this.sortDirection === 'asc' ? -1 : 1;
      if (aValue > bValue) return this.sortDirection === 'asc' ? 1 : -1;
      return 0;
    });
  },

  setSort(field) {
    if (this.sortField === field) {
      this.sortDirection = this.sortDirection === 'asc' ? 'desc' : 'asc';
    } else {
      this.sortField = field;
      this.sortDirection = 'asc';
    }
  },

  async loadHandlers() {
    this.isLoading = true;

    try {
      const response = await fetch('api/getHandlersList');
      const result = await handleFetchResponse(response);
      if (!result.success) throw new Error(result.message);
      this.handlers = result.data || [];
    } catch (error) {
      window.dispatchEvent(new CustomEvent('show-error', {
        detail: { message: `Ошибка загрузки: ${error.message}` }
      }));
      console.error('Ошибка загрузки:', error);
      this.handlers = [];
    } finally {
      this.isLoading = false;
    }
  },

  async toggleHandlerStatus(handler) {
    const newStatus = handler.active == 1 ? 0 : 1;

    try {
      const formData = new URLSearchParams();
      formData.append('key', handler.key);
      formData.append('active', newStatus);

      const response = await fetch('api/updateStatus', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: formData
      });

      if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);

      const result = await response.json();
      if (!result.result) throw new Error(result.error || 'Ошибка сервера');

      handler.active = newStatus;

      window.dispatchEvent(new CustomEvent('show-success', {
        detail: { message: `Статус обработчика "${handler.key}" изменён на ${newStatus === 1 ? '"Активный"' : '"Неактивный"'}` }
      }));
    } catch (error) {
      console.error('Ошибка изменения статуса:', error);
      window.dispatchEvent(new CustomEvent('show-error', {
        detail: { message: `Ошибка изменения статуса "${handler.key}": ${error.message}` }
      }));
      handler.active = handler.active == 1 ? 0 : 1;
    }
  },

  async editHandler(handler) {
    const formData = new URLSearchParams();
    formData.append('key', handler.key);

    try {
      const response = await fetch('api/getHandler', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: formData
      });

      if (!response.ok) throw new Error('Ошибка загрузки');

      const result = await response.json();
      if (!result.result) throw new Error(result.error || 'Неизвестная ошибка');

      window.handlerToEdit = result.data;
      window.location.hash = '#handler-form';
    } catch (error) {
      console.error('Ошибка загрузки:', error);
      window.dispatchEvent(new CustomEvent('show-error', {
        detail: { message: `Ошибка загрузки: ${error.message}` }
      }));
    }
  },

  addNewHandler() {
    window.location.hash = '#handler-form';
  },

  getCurrentDate() {
    const today = new Date();
    return `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, '0')}-${String(today.getDate()).padStart(2, '0')}`;
  },

  deleteHandler(handler) {
    if (!confirm(`Вы уверены, что хотите удалить обработчик "${handler.key}"?`)) return;

    const formData = new URLSearchParams();
    formData.append('key', handler.key);

    fetch('api/deleteHandler', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: formData
    })
      .then(async (response) => {
        const result = await handleFetchResponse(response);
        if (!result.success) throw new Error(result.message);

        this.handlers = this.handlers.filter(h => h.key !== handler.key);
        window.dispatchEvent(new CustomEvent('show-success', {
          detail: { message: `Обработчик "${handler.key}" удален` }
        }));
      })
      .catch((error) => {
        window.dispatchEvent(new CustomEvent('show-error', {
          detail: { message: `Ошибка при удалении "${handler.key}": ${error.message}` }
        }));
      });
  },

  handleImageError(event) {
    event.target.src = 'img/libs/default.png';
    event.target.onerror = null;
  }
  
});