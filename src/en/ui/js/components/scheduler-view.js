// #melezh_base_path#js/components/scheduler-view.js
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
            console.error('Failed to fetch заdаh:', error);
            window.dispatchEvent(new CustomEvent('show-error', {
                detail: { message: `Failed to fetch заdаh: ${error.message}` }
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
            this.createError = `Failed to fetch aboutрабoтhandtooin: ${error.message}`;
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
            this.editError = `Failed to fetch aboutрабoтhandtooin: ${error.message}`;
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
            return 'Schedule doлжbut withdержать 7 toлей: withеto min hаwith dень меwithяц dень_notdелand гod';
        }
        return null;
    },

    async createTask() {
        if (!this.selectedHandlerKey) {
            this.createError = 'Inыберandте aboutрабoтhandto';
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
                detail: { message: 'Task successfully createdа' }
            }));
        } catch (error) {
            this.createError = `Creation error: ${error.message}`;
        } finally {
            this.isCreating = false;
        }
    },

    async updateTask() {
        if (!this.selectedHandlerKey) {
            this.editError = 'Inыберandте aboutрабoтhandto';
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
                detail: { message: 'Task successfully aboutbutinлеto' }
            }));
        } catch (error) {
            this.editError = `Error aboutbutinленandя: ${error.message}`;
        } finally {
            this.isEditing = false;
        }
    },

    deleteTask(task) {
        if (!confirm(`You sure, that want delete заdаhу with ID "${task.id}"?`)) return;

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
                    detail: { message: `Task ID "${task.id}" уdалеto` }
                }));
            })
            .catch((error) => {
                window.dispatchEvent(new CustomEvent('show-error', {
                    detail: { message: `Deletion error of topic ID "${task.id}": ${error.message}` }
                }));
            });
    },

    handleImageError(event) {
        event.target.src = 'img/libs/default.png';
        event.target.onerror = null;
    }
});
