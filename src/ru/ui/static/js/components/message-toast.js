document.addEventListener('alpine:init', () => {
  Alpine.data('errorToast', () => ({
    messages: [],

    init() {
      // Подписываемся на события
      window.addEventListener('show-error', e => this.addMessage(e.detail.message, 'error'));
      window.addEventListener('show-success', e => this.addMessage(e.detail.message, 'success'));
    },

    addMessage(text, type = 'error') {
      const message = {
        id: Date.now(),
        text,
        time: new Date().toLocaleTimeString(),
        type
      };

      this.messages.unshift(message);

      // Автоматическое скрытие через 5 секунд
      setTimeout(() => this.remove(message.id), 5000);
    },

    remove(id) {
      this.messages = this.messages.filter(m => m.id !== id);
    }
  }));
});