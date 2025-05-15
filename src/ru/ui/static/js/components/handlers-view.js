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
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      
      const data = await response.json();
      
      if (!data.result) {
        throw new Error(data.error || 'Неизвестная ошибка сервера');
      }
      
      this.handlers = data.data || [];
    } catch (error) {
      console.error('Ошибка загрузки обработчиков:', error);
      this.errorMessage = `Ошибка загрузки: ${error.message}`;
      this.handlers = [];
    } finally {
      this.isLoading = false;
    }
  },
  
async toggleHandlerStatus(handler) {
  try {
    const newStatus = handler.active == 1 ? 0 : 1;

    // Подготавливаем данные формы
    const formData = new URLSearchParams();
    formData.append('key', handler.key);
    formData.append('active', newStatus);

    const response = await fetch('/api/updateStatus', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: formData
    });

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    const result = await response.json();

    if (!result.result) {
      throw new Error(result.error || 'Ошибка сервера');
    }

    // Обновляем статус локально только после успешного ответа
    handler.active = newStatus;
  } catch (error) {
    console.error('Ошибка изменения статуса:', error);
    this.errorMessage = `Ошибка: ${error.message}`;

    // Восстанавливаем предыдущее состояние тумблера при ошибке
    handler.active = handler.active == 1 ? 0 : 1;
  }
},

addNewHandler() {
  window.location.hash = '#handler-form';
}

});