import { dashboardView } from './dashboard-view.js';
import { handlersView } from './handlers-view.js';
import { handlerFormView } from './handler-form-view.js';

document.addEventListener('alpine:init', () => {
  Alpine.data('dashboardView', dashboardView);
  Alpine.data('handlersView', handlersView);
  Alpine.data('handlerFormView', handlerFormView);
});