import { handleFetchResponse } from '#melezh_base_path#js/error-fetch.js';

export const schedulerView = () => ({
    tasks: [],
    isLoading: false,

    // Modal
    showCreateModal: false,
    showEditModal: false,
    handlers: [],
    isHandlersLoading: true,
    selectedHandlerKey: '',
    handlerDropdownOpen: false,
    handlerSearch: '',

    scheduleInput: '0 0 9 * * * *',
    createError: '',
    editError: '',
    isCreating: false,
    isEditing: false,
    editingTask: null,

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

    async openEditModal(task) {
        this.showEditModal = true;
        this.editError = '';
        this.isEditing = false;
        this.editingTask = task;
        this.selectedHandlerKey = task.handler;
        this.scheduleInput = task.cron;
        this.handlerSearch = '';

        try {
            const response = await fetch('api/getHandlersList');
            const result = await handleFetchResponse(response);
            if (!result.success) throw new Error(result.message);
            this.handlers = result.data || [];
        } catch (error) {
            this.editError = `Ошибка загрузки обработчиков: ${error.message}`;
        } finally {
            this.isHandlersLoading = false;
        }
    },

    closeCreateModal() {
        this.showCreateModal = false;
        this.handlerDropdownOpen = false;
    },

    closeEditModal() {
        this.showEditModal = false;
        this.handlerDropdownOpen = false;
        this.editingTask = null;
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

    validateSchedule(schedule) {
        const parts = schedule.trim().split(/\s+/);
        if (parts.length !== 7) {
            return 'Расписание должно содержать 7 полей: сек мин час день месяц день_недели год';
        }
        return null;
    },

    async createTask() {
        if (!this.selectedHandlerKey) {
            this.createError = 'Выберите обработчик';
            return;
        }

        const scheduleValidation = this.validateSchedule(this.scheduleInput);
        if (scheduleValidation) {
            this.createError = scheduleValidation;
            return;
        }

        this.isCreating = true;
        this.createError = '';

        try {
            const payload = {
                handler: this.selectedHandlerKey,
                schedule: this.scheduleInput.trim()
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
            
            window.dispatchEvent(new CustomEvent('show-success', {
                detail: { message: 'Задача успешно создана' }
            }));
        } catch (error) {
            this.createError = `Ошибка создания: ${error.message}`;
        } finally {
            this.isCreating = false;
        }
    },

    async updateTask() {
        if (!this.selectedHandlerKey) {
            this.editError = 'Выберите обработчик';
            return;
        }

        const scheduleValidation = this.validateSchedule(this.scheduleInput);
        if (scheduleValidation) {
            this.editError = scheduleValidation;
            return;
        }

        this.isEditing = true;
        this.editError = '';

        try {
            const payload = {
                id: this.editingTask.id,
                handler: this.selectedHandlerKey,
                schedule: this.scheduleInput.trim()
            };

            const response = await fetch('api/updateSchedulerTask', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(payload)
            });

            const result = await handleFetchResponse(response);
            if (!result.success) throw new Error(result.message);

            this.closeEditModal();
            await this.loadTasks();
            
            window.dispatchEvent(new CustomEvent('show-success', {
                detail: { message: 'Задача успешно обновлена' }
            }));
        } catch (error) {
            this.editError = `Ошибка обновления: ${error.message}`;
        } finally {
            this.isEditing = false;
        }
    },

    async deleteTask(task) {
        if (!confirm(`Вы уверены, что хотите удалить задачу с ID "${task.id}"?`)) return;

        try {
            const payload = {
                id: task.id
            };

            const response = await fetch('api/deleteSchedulerTask', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(payload)
            });

            const result = await handleFetchResponse(response);
            if (!result.success) throw new Error(result.message);

            this.tasks = this.tasks.filter(t => t.id !== task.id);
            window.dispatchEvent(new CustomEvent('show-success', {
                detail: { message: `Задача ID "${task.id}" удалена` }
            }));
        } catch (error) {
            window.dispatchEvent(new CustomEvent('show-error', {
                detail: { message: `Ошибка при удалении задачи ID "${task.id}": ${error.message}` }
            }));
        }
    },

    // Новый метод для переключения статуса задачи
    async toggleTaskStatus(task) {
        const newStatus = task.active == 1 ? 0 : 1;

        try {
            const payload = {
                id: task.id,
                active: newStatus
            };

            const response = await fetch('api/updateSchedulerTaskStatus', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(payload)
            });

            const result = await handleFetchResponse(response);
            if (!result.success) throw new Error(result.message);

            await this.refreshTaskData(task);

            window.dispatchEvent(new CustomEvent('show-success', {
                detail: { 
                    message: `Статус задачи "${task.id}" изменён на ${newStatus === 1 ? '"Активная"' : '"Неактивная"'}`
                }
            }));
        } catch (error) {
            console.error('Ошибка изменения статуса:', error);
            window.dispatchEvent(new CustomEvent('show-error', {
                detail: { 
                    message: `Ошибка изменения статуса задачи "${task.id}": ${error.message}`
                }
            }));
            task.active = task.active == 1 ? 0 : 1;
        }
    },

    async refreshTaskData(task) {
        try {
            const response = await fetch('api/getSchedulerTasks');
            const result = await handleFetchResponse(response);
            if (!result.success) throw new Error(result.message);
            
            const updatedTasks = Array.isArray(result.data) ? result.data : [];
            const updatedTask = updatedTasks.find(t => t.id === task.id);
            
            if (updatedTask) {
                task.active = updatedTask.active;
                task.last_launch = updatedTask.last_launch;
                task.next_launch = updatedTask.next_launch;
                task.cron = updatedTask.cron;
                task.handler = updatedTask.handler;
            }
        } catch (error) {
            console.error('Ошибка обновления данных задачи:', error);
            await this.loadTasks();
        }
    },

    formatDateTime(dateString) {
        if (!dateString || dateString === '0000-00-00 00:00:00' || dateString === 'Never' || dateString === 'Disabled') {
            return '-';
        }
        
        try {
            const date = new Date(dateString);
            if (isNaN(date.getTime())) {
                return '-';
            }
            
            return date.toLocaleString('ru-RU', {
                day: '2-digit',
                month: '2-digit',
                year: 'numeric',
                hour: '2-digit',
                minute: '2-digit',
                second: '2-digit'
            });
        } catch (error) {
            console.error('Ошибка форматирования даты:', error);
            return '-';
        }
    },

    getLastLaunchAgo(task) {
        if (!task.last_launch || task.last_launch === '0000-00-00 00:00:00' || task.last_launch === 'Never' || task.last_launch === 'Disabled') {
            return { text: 'Никогда', class: 'text-gray-500' };
        }
        
        try {
            const lastLaunch = new Date(task.last_launch);
            const now = new Date();
            
            if (isNaN(lastLaunch.getTime())) {
                return { text: 'Ошибка даты', class: 'text-red-500' };
            }
            
            const diffMs = now - lastLaunch;
            const diffSeconds = Math.floor(diffMs / 1000);
            const diffMinutes = Math.floor(diffSeconds / 60);
            const diffHours = Math.floor(diffMinutes / 60);
            const diffDays = Math.floor(diffHours / 24);
            
            if (diffSeconds < 60) {
                return { text: `${diffSeconds} сек назад`, class: 'text-green-600 font-semibold' };
            } else if (diffMinutes < 60) {
                return { text: `${diffMinutes} мин назад`, class: 'text-green-600' };
            } else if (diffHours < 24) {
                return { text: `${diffHours} ч назад`, class: 'text-blue-600' };
            } else {
                return { text: `${diffDays} д назад`, class: 'text-gray-600' };
            }
        } catch (error) {
            console.error('Ошибка расчета времени:', error);
            return { text: 'Ошибка', class: 'text-red-500' };
        }
    },

    getNextLaunchStatus(task) {
        if (!task.next_launch || task.next_launch === '0000-00-00 00:00:00' || task.next_launch === 'Never' || task.next_launch === 'Disabled') {
            return { text: 'Не запланирован', class: 'text-gray-500' };
        }
        
        const nextLaunch = new Date(task.next_launch);
        const now = new Date();
        
        if (nextLaunch < now) {
            return { text: 'Просрочен', class: 'text-red-600 font-semibold' };
        }
        
        const diffMs = nextLaunch - now;
        const diffHours = Math.floor(diffMs / (1000 * 60 * 60));
        
        if (diffHours < 1) {
            const diffMinutes = Math.floor(diffMs / (1000 * 60));
            return { text: `Через ${diffMinutes} мин`, class: 'text-green-600' };
        } else if (diffHours < 24) {
            return { text: `Через ${diffHours} ч`, class: 'text-green-600' };
        } else {
            const diffDays = Math.floor(diffHours / 24);
            return { text: `Через ${diffDays} д`, class: 'text-blue-600' };
        }
    },

    handleImageError(event) {
        event.target.src = 'img/libs/default.png';
        event.target.onerror = null;
    }
});