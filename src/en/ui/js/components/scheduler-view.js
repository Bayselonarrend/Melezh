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
            console.error('Error loading tasks:', error);
            window.dispatchEvent(new CustomEvent('show-error', {
                detail: { message: `Error loading tasks: ${error.message}` }
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
            this.createError = `Handler loading error: ${error.message}`;
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
            this.editError = `Handler loading error: ${error.message}`;
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
            return 'Schedule must contain 7 fields: sec min hour day month day_of_week year';
        }
        return null;
    },

    async createTask() {
        if (!this.selectedHandlerKey) {
            this.createError = 'Choose handler';
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
                detail: { message: 'Task created successfully' }
            }));
        } catch (error) {
            this.createError = `Creation error: ${error.message}`;
        } finally {
            this.isCreating = false;
        }
    },

    async updateTask() {
        if (!this.selectedHandlerKey) {
            this.editError = 'Choose handler';
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
                detail: { message: 'Task updated successfully' }
            }));
        } catch (error) {
            this.editError = `Update error: ${error.message}`;
        } finally {
            this.isEditing = false;
        }
    },

    async deleteTask(task) {
        if (!confirm(`Are you sure you want to delete the task with ID "${task.id}"?`)) return;

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
                detail: { message: `Task ID "${task.id}" deleted` }
            }));
        } catch (error) {
            window.dispatchEvent(new CustomEvent('show-error', {
                detail: { message: `Error deleting task ID "${task.id}": ${error.message}` }
            }));
        }
    },

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
                    message: `Task status "${task.id}" changed to ${newStatus === 1 ? '"Active"' : '"Inactive"'}`
                }
            }));
        } catch (error) {
            console.error('Status change error:', error);
            window.dispatchEvent(new CustomEvent('show-error', {
                detail: { 
                    message: `Error changing task status "${task.id}": ${error.message}`
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
            console.error('Error updating task data:', error);
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
            console.error('Date formatting error:', error);
            return '-';
        }
    },

    getLastLaunchAgo(task) {
        if (!task.last_launch || task.last_launch === '0000-00-00 00:00:00' || task.last_launch === 'Never' || task.last_launch === 'Disabled') {
            return { text: 'Never', class: 'text-gray-500' };
        }
        
        try {
            const lastLaunch = new Date(task.last_launch);
            const now = new Date();
            
            if (isNaN(lastLaunch.getTime())) {
                return { text: 'Date error', class: 'text-red-500' };
            }
            
            const diffMs = now - lastLaunch;
            const diffSeconds = Math.floor(diffMs / 1000);
            const diffMinutes = Math.floor(diffSeconds / 60);
            const diffHours = Math.floor(diffMinutes / 60);
            const diffDays = Math.floor(diffHours / 24);
            
            if (diffSeconds < 60) {
                return { text: `${diffSeconds} sec ago`, class: 'text-green-600 font-semibold' };
            } else if (diffMinutes < 60) {
                return { text: `${diffMinutes} min ago`, class: 'text-green-600' };
            } else if (diffHours < 24) {
                return { text: `${diffHours} hr ago`, class: 'text-blue-600' };
            } else {
                return { text: `${diffDays} day ago`, class: 'text-gray-600' };
            }
        } catch (error) {
            console.error('Time calculation error:', error);
            return { text: 'Error', class: 'text-red-500' };
        }
    },

    getNextLaunchStatus(task) {
        if (!task.next_launch || task.next_launch === '0000-00-00 00:00:00' || task.next_launch === 'Never' || task.next_launch === 'Disabled') {
            return { text: 'Not scheduled', class: 'text-gray-500' };
        }
        
        const nextLaunch = new Date(task.next_launch);
        const now = new Date();
        
        if (nextLaunch < now) {
            return { text: 'Overdue', class: 'text-red-600 font-semibold' };
        }
        
        const diffMs = nextLaunch - now;
        const diffHours = Math.floor(diffMs / (1000 * 60 * 60));
        
        if (diffHours < 1) {
            const diffMinutes = Math.floor(diffMs / (1000 * 60));
            return { text: `In ${diffMinutes} min`, class: 'text-green-600' };
        } else if (diffHours < 24) {
            return { text: `In ${diffHours} h`, class: 'text-green-600' };
        } else {
            const diffDays = Math.floor(diffHours / 24);
            return { text: `In ${diffDays} d`, class: 'text-blue-600' };
        }
    },

    handleImageError(event) {
        event.target.src = 'img/libs/default.png';
        event.target.onerror = null;
    }
});
