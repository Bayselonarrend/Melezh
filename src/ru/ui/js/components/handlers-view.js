import { handleFetchResponse } from '#melezh_base_path#js/error-fetch.js';

export const handlersView = () => ({
  handlers: [],
  isLoading: false,

  async init() {
    await this.loadHandlers();
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
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded'
        },
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
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: formData
      });

      if (!response.ok) throw new Error('Ошибка загрузки');

      const result = await response.json();

      if (!result.result) throw new Error(result.error || 'Неизвестная ошибка');

      window.handlerToEdit = result.data;

      // Переход к форме
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
    const year = today.getFullYear();
    const month = String(today.getMonth() + 1).padStart(2, '0');
    const day = String(today.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  },
  
  deleteHandler(handler) {
    if (!confirm(`Вы уверены, что хотите удалить обработчик "${handler.key}"?`)) return;

    const formData = new URLSearchParams();
    formData.append('key', handler.key);

    fetch('api/deleteHandler', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      body: formData
    })
      .then(async (response) => {

        const result = await handleFetchResponse(response);
        if (!result.success) throw new Error(result.message);

        // Удаляем из списка
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
  }

});