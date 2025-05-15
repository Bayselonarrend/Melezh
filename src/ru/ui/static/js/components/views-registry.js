// Предварительная регистрация всех компонентов
import { dashboardView } from './dashboard-view.js';
import { handlersView } from './handlers-view.js';

document.addEventListener('alpine:init', () => {
  Alpine.data('dashboardView', dashboardView);
  Alpine.data('handlersView', handlersView);
  // Добавьте другие компоненты по мере необходимости
});