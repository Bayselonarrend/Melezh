import { dashboardView } from '#melezh_base_path#js/components/dashboard-view.js';
import { handlersView } from '#melezh_base_path#js/components/handlers-view.js';
import { handlerFormView } from '#melezh_base_path#js/components/handler-form-view.js';
import { settingsPage } from '#melezh_base_path#js/components/settings-view.js';
import { logsView } from '#melezh_base_path#js/components/logs-view.js';
import { logDetailsView } from '#melezh_base_path#js/components/log-details-view.js';
import { extensionsView } from '#melezh_base_path#js/components/extensions-view.js';
import { codeEditorView } from '#melezh_base_path#js/components/code-editor-view.js';
import { schedulerView } from '#melezh_base_path#js/components/scheduler-view.js';

document.addEventListener('alpine:init', () => {
  Alpine.data('dashboardView', dashboardView);
  Alpine.data('handlersView', handlersView);
  Alpine.data('handlerFormView', handlerFormView);
  Alpine.data('settingsPage', settingsPage);
  Alpine.data('logsView', logsView);
  Alpine.data('logDetailsView', logDetailsView);
  Alpine.data('extensionsView', extensionsView);
  Alpine.data('codeEditorView', codeEditorView);
  Alpine.data('schedulerView', schedulerView);

});
