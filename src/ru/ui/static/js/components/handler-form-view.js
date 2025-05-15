export const handlerFormView = () => ({
  formData: {
    key: '',
    method: '',
    library: '',
    function: ''
  },
  errorMessage: '',
  isLoading: false,

  // Можно вызвать при необходимости
  init() {},

  async submitForm() {
    this.errorMessage = '';
    this.isLoading = true;

    try {
      const response = await fetch('/api/createHandler', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(this.formData)
      });

      if (!response.ok) {
        throw new Error('Ошибка сервера');
      }

      const result = await response.json();

      if (!result.result) {
        throw new Error(result.error || 'Неизвестная ошибка');
      }

      // Переключаемся обратно на handlers
      Alpine.store('router').loadView('handlers');

    } catch (error) {
      console.error('Ошибка при создании обработчика:', error);
      this.errorMessage = error.message;
    } finally {
      this.isLoading = false;
    }
  },

cancel() {
  window.location.hash = '#handlers';
}
});