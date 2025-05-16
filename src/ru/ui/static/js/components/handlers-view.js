export const handlersView = () => ({
  handlers: [],
  isLoading: false,
  errorMessage: '',

  async init() {
    await this.loadHandlers();
  },

  async loadHandlers() {
    this.isLoading = true;
    this.errorMessage = '';

    try {
      const response = await fetch('/api/getHandlersList');
      if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
      const data = await response.json();
      if (!data.result) throw new Error(data.error || 'Неизвестная ошибка');
      this.handlers = data.data || [];
    } catch (error) {
      console.error('Ошибка загрузки обработчиков:', error);
      this.errorMessage = error.message;
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

      const response = await fetch('/api/updateStatus', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: formData
      });

      if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);

      const result = await response.json();

      if (!result.result) throw new Error(result.error || 'Ошибка сервера');

      // Обновляем статус локально только после успешного ответа
      handler.active = newStatus;

      // Показываем успех через твой toast
      window.dispatchEvent(new CustomEvent('show-success', {
        detail: { message: `Статус обработчика "${handler.key}" изменён на ${newStatus === 1 ? 'активный' : 'неактивный'}` }
      }));
    } catch (error) {
      console.error('Ошибка изменения статуса:', error);
      window.dispatchEvent(new CustomEvent('show-error', {
        detail: { message: `Ошибка изменения статуса "${handler.key}": ${error.message}` }
      }));

      // Восстанавливаем предыдущее состояние
      handler.active = handler.active == 1 ? 0 : 1;
    }
  },

  async editHandler(handler) {
    const formData = new URLSearchParams();
    formData.append('key', handler.key);

    try {
      const response = await fetch('/api/getHandler', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: formData
      });

      if (!response.ok) throw new Error('Ошибка загрузки данных');

      const result = await response.json();

      if (!result.result) throw new Error(result.error || 'Неизвестная ошибка');

      // Сохраняем данные в глобальной переменной
      window.handlerToEdit = result.data;

      // Переход к форме
      window.location.hash = '#handler-form';
    } catch (error) {
      console.error('Ошибка получения обработчика:', error);
      window.dispatchEvent(new CustomEvent('show-error', {
        detail: { message: `Ошибка при открытии формы редактирования: ${error.message}` }
      }));
    }
  },

  addNewHandler() {
    window.location.hash = '#handler-form';
  },

  deleteHandler(handler) {
    if (!confirm(`Вы уверены, что хотите удалить обработчик "${handler.key}"?`)) return;

    const formData = new URLSearchParams();
    formData.append('key', handler.key);

    fetch('/api/deleteHandler', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      body: formData
    })
      .then(async (response) => {
        if (!response.ok) throw new Error('Ошибка сети');

        const result = await response.json();

        if (!result.result) throw new Error(result.error || 'Неизвестная ошибка');

        // Удаляем из списка
        this.handlers = this.handlers.filter(h => h.key !== handler.key);

        // Показываем успех
        window.dispatchEvent(new CustomEvent('show-success', {
          detail: { message: `Обработчик "${handler.key}" удален` }
        }));
      })
      .catch((error) => {
        // Показываем ошибку
        window.dispatchEvent(new CustomEvent('show-error', {
          detail: { message: `Ошибка при удалении "${handler.key}": ${error.message}` }
        }));
      });
  }

});