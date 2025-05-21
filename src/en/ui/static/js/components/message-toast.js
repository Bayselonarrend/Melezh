document.addEventListener('alpine:init', () => {
  Alpine.data('errorToast', () => ({
    messages: [],

    init() {
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

      setTimeout(() => this.remove(message.id), 10000);
    },

    remove(id) {
      this.messages = this.messages.filter(m => m.id !== id);
    }
  }));
});
