// #melezh_base_path#js/components/scheduler-view.js
import { handleFetchResponse } from '#melezh_base_path#js/error-fetch.js';

export const schedulerView = () => ({
    tasks: [],
    isLoading: false,

    // Modal
    showCreateModal: false,
    handlers: [],
    isHandlersLoading: true,
    selectedHandlerKey: '',
    handlerDropdownOpen: false,
    handlerSearch: '',

    scheduleInput: '0 0 9 * * * *',
    createError: '',
    isCreating: false,

    init() {
        this.loadTasks();
    },

    async loadTasks() {
        this.isLoading = true;
        try {
            const response = await fetch('api/getSchedulerTasks');
            const result = await handleFetchResponse(response);
            if (!result.success) throw new Error(result.message);
            this.tasks = Array.isArray(result.data) ? result.data : [];
        } catch (error) {
            console.error('Ошибка загрузки задач:', error);
            window.dispatchEvent(new CustomEvent('show-error', {
                detail: { message: `Ошибка загрузки задач: ${error.message}` }
            }));
            this.tasks = [];
        } finally {
            this.isLoading = false;
        }
    },

    async openCreateModal() {
        this.showCreateModal = true;
        this.createError = '';
        this.isCreating = false;
        this.selectedHandlerKey = '';
        this.handlerSearch = '';
        this.scheduleInput = '0 0 9 * * * *';

        try {
            const response = await fetch('api/getHandlersList');
            const result = await handleFetchResponse(response);
            if (!result.success) throw new Error(result.message);
            this.handlers = result.data || [];
        } catch (error) {
            this.createError = `Ошибка загрузки обработчиков: ${error.message}`;
        } finally {
            this.isHandlersLoading = false;
        }
    },

    closeCreateModal() {
        this.showCreateModal = false;
        this.handlerDropdownOpen = false;
    },

    get filteredHandlers() {
        if (!this.handlerSearch.trim()) return this.handlers;
        const term = this.handlerSearch.toLowerCase();
        return this.handlers.filter(h =>
            h.key.toLowerCase().includes(term) ||
            h.library_title.toLowerCase().includes(term)
        );
    },

    openHandlerDropdown() {
        if (this.isHandlersLoading) return;
        if (this.handlerDropdownOpen) {
            this.closeHandlerDropdown();
            return;
        }
        this.handlerSearch = '';
        this.handlerDropdownOpen = true;
        this.$nextTick(() => {
            if (this.$refs && this.$refs.handlerSearchInput) {
                this.$refs.handlerSearchInput.focus();
            }
        });
    },

    closeHandlerDropdown() {
        this.handlerDropdownOpen = false;
    },

    selectHandler(key) {
        this.selectedHandlerKey = key;
        this.closeHandlerDropdown();
    },

    async createTask() {
        if (!this.selectedHandlerKey) {
            this.createError = 'Выберите обработчик';
            return;
        }

        const schedule = this.scheduleInput.trim();
        const parts = schedule.split(/\s+/);
        if (parts.length !== 7) {
            this.createError = 'Расписание должно содержать 7 полей: сек мин час день месяц день_недели год';
            return;
        }

        this.isCreating = true;
        this.createError = '';

        try {
            const payload = {
                handler: this.selectedHandlerKey,
                schedule: schedule
            };

            const response = await fetch('api/createSchedulerTask', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(payload)
            });

            const result = await handleFetchResponse(response);
            if (!result.success) throw new Error(result.message);

            this.closeCreateModal();
            await this.loadTasks();
        } catch (error) {
            this.createError = `Ошибка создания: ${error.message}`;
        } finally {
            this.isCreating = false;
        }
    },

    deleteTask(task) {
        if (!confirm(`Вы уверены, что хотите удалить задачу с ID "${task.id}"?`)) return;

        const formData = new URLSearchParams();
        formData.append('id', task.id);

        fetch('api/deleteSchedulerTask', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: formData
        })
            .then(async (response) => {
                const result = await handleFetchResponse(response);
                if (!result.success) throw new Error(result.message);

                this.tasks = this.tasks.filter(t => t.id !== task.id);
                window.dispatchEvent(new CustomEvent('show-success', {
                    detail: { message: `Задача ID "${task.id}" удалена` }
                }));
            })
            .catch((error) => {
                window.dispatchEvent(new CustomEvent('show-error', {
                    detail: { message: `Ошибка при удалении задачи ID "${task.id}": ${error.message}` }
                }));
            });
    },

    handleImageError(event) {
        event.target.src = 'img/libs/default.png';
        event.target.onerror = null;
    }
});