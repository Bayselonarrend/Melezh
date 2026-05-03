import { handleFetchResponse } from '#melezh_base_path#js/error-fetch.js';
import {
    defaultScheduleModel,
    tryParseScheduleString,
    buildScheduleString,
} from '#melezh_base_path#js/schedule-cron.js';

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
    scheduleCronModel: defaultScheduleModel(),
    scheduleConstructorInSync: true,
    scheduleConstructorHint: '',
    _scheduleBuildingFromConstruct: false,
    // Порядок Пн…Вс, значения cron как в Chronos/rust crate (вс = 1, пн = 2 … сб = 7)
    scheduleWeekdays: [
        { label: 'Пн', cron: 2 },
        { label: 'Вт', cron: 3 },
        { label: 'Ср', cron: 4 },
        { label: 'Чт', cron: 5 },
        { label: 'Пт', cron: 6 },
        { label: 'Сб', cron: 7 },
        { label: 'Вс', cron: 1 },
    ],
    scheduleMonthNames: ['янв.', 'февр.', 'мар.', 'апр.', 'мая', 'июн.', 'июл.', 'авг.', 'сен.', 'окт.', 'нояб.', 'дек.'],
    createError: '',
    editError: '',
    isCreating: false,
    isEditing: false,
    editingTask: null,

    init() {
        this.loadTasks();
    },

    get scheduleSecondMarks() {
        return Array.from({ length: 60 }, (_, i) => i);
    },

    get scheduleMinuteMarks() {
        return Array.from({ length: 60 }, (_, i) => i);
    },

    get scheduleHourMarks() {
        return Array.from({ length: 24 }, (_, i) => i);
    },

    get scheduleDomMarks() {
        return Array.from({ length: 31 }, (_, i) => i + 1);
    },

    get scheduleMonthMarks() {
        return Array.from({ length: 12 }, (_, i) => i + 1);
    },

    cloneCronModel(src) {
        return {
            seconds: src.seconds === '*' ? '*' : [...src.seconds],
            minutes: src.minutes === '*' ? '*' : [...src.minutes],
            hours: src.hours === '*' ? '*' : [...src.hours],
            dom: src.dom === '*' ? '*' : [...src.dom],
            months: src.months === '*' ? '*' : [...src.months],
            dow: src.dow === '*' ? '*' : [...src.dow],
            years: src.years === '*' ? '*' : [...src.years],
        };
    },

    syncScheduleFromInput() {
        if (this._scheduleBuildingFromConstruct) return;
        const trimmed = String(this.scheduleInput ?? '').trim();
        if (!trimmed.split(/\s+/).filter(Boolean).length) {
            this.scheduleConstructorInSync = false;
            this.scheduleConstructorHint = 'Введите 7 полей расписания.';
            return;
        }
        const r = tryParseScheduleString(trimmed);
        if (r.ok) {
            this.scheduleCronModel = this.cloneCronModel(r.model);
            this.scheduleConstructorInSync = true;
            this.scheduleConstructorHint = '';
        } else {
            this.scheduleConstructorInSync = false;
            this.scheduleConstructorHint = r.reason;
        }
    },

    emitScheduleFromModel() {
        this._scheduleBuildingFromConstruct = true;
        this.scheduleInput = buildScheduleString(this.scheduleCronModel);
        this.scheduleConstructorInSync = true;
        this.scheduleConstructorHint = '';
        queueMicrotask(() => {
            this._scheduleBuildingFromConstruct = false;
        });
    },

    scheduleYearsAreMultiple() {
        const y = this.scheduleCronModel.years;
        return Array.isArray(y) && y.length > 1;
    },

    /**
     * @param {'seconds'|'minutes'|'hours'} key
     */
    scheduleTimeIsStar(key) {
        return this.scheduleCronModel[key] === '*';
    },

    /**
     * @param {'seconds'|'minutes'|'hours'} key
     */
    scheduleTimeIsOn(key, v) {
        const part = this.scheduleCronModel[key];
        if (part === '*') return true;
        return Array.isArray(part) && part.includes(v);
    },

    /**
     * @param {'seconds'|'minutes'|'hours'} key
     */
    scheduleToggleTime(key, min, max, v, fallbackWhenEmpty) {
        let part = this.scheduleCronModel[key];
        const fullCount = max - min + 1;
        let set;
        if (part === '*') {
            set = new Set();
            for (let i = min; i <= max; i += 1) set.add(i);
        } else {
            set = new Set(part);
        }
        if (set.has(v)) set.delete(v);
        else set.add(v);

        if (set.size === 0) {
            this.scheduleCronModel[key] = [fallbackWhenEmpty];
        } else if (set.size === fullCount) {
            this.scheduleCronModel[key] = '*';
        } else {
            this.scheduleCronModel[key] = [...set].sort((a, b) => a - b);
        }
        this.emitScheduleFromModel();
    },

    /**
     * @param {'seconds'|'minutes'|'hours'} key
     */
    scheduleSetTimeStar(key, starred, _min, _max, fallback) {
        if (starred) {
            this.scheduleCronModel[key] = '*';
        } else {
            const cur = this.scheduleCronModel[key];
            if (cur === '*' || !Array.isArray(cur) || cur.length === 0) {
                this.scheduleCronModel[key] = [fallback];
            }
        }
        this.emitScheduleFromModel();
    },

    scheduleDomIsStar() {
        return this.scheduleCronModel.dom === '*';
    },

    scheduleDomIsOn(d) {
        const part = this.scheduleCronModel.dom;
        if (part === '*') return true;
        return part.includes(d);
    },

    scheduleToggleDom(d) {
        const min = 1;
        const max = 31;
        let part = this.scheduleCronModel.dom;
        let set;
        if (part === '*') {
            set = new Set();
            for (let i = min; i <= max; i += 1) set.add(i);
        } else {
            set = new Set(part);
        }
        if (set.has(d)) set.delete(d);
        else set.add(d);
        if (set.size === 0) {
            this.scheduleCronModel.dom = [1];
        } else if (set.size === max) {
            this.scheduleCronModel.dom = '*';
        } else {
            this.scheduleCronModel.dom = [...set].sort((a, b) => a - b);
        }
        this.emitScheduleFromModel();
    },

    scheduleSetDomStar(starred) {
        if (starred) {
            this.scheduleCronModel.dom = '*';
        } else {
            const cur = this.scheduleCronModel.dom;
            if (cur === '*' || !Array.isArray(cur) || cur.length === 0) {
                this.scheduleCronModel.dom = [1];
            }
        }
        this.emitScheduleFromModel();
    },

    scheduleMonthIsStar() {
        return this.scheduleCronModel.months === '*';
    },

    scheduleMonthIsOn(m) {
        const part = this.scheduleCronModel.months;
        if (part === '*') return true;
        return part.includes(m);
    },

    scheduleToggleMonth(m) {
        const min = 1;
        const max = 12;
        let part = this.scheduleCronModel.months;
        let set;
        if (part === '*') {
            set = new Set();
            for (let i = min; i <= max; i += 1) set.add(i);
        } else {
            set = new Set(part);
        }
        if (set.has(m)) set.delete(m);
        else set.add(m);
        if (set.size === 0) {
            this.scheduleCronModel.months = [1];
        } else if (set.size === max) {
            this.scheduleCronModel.months = '*';
        } else {
            this.scheduleCronModel.months = [...set].sort((a, b) => a - b);
        }
        this.emitScheduleFromModel();
    },

    scheduleSetMonthStar(starred) {
        if (starred) {
            this.scheduleCronModel.months = '*';
        } else {
            const cur = this.scheduleCronModel.months;
            if (cur === '*' || !Array.isArray(cur) || cur.length === 0) {
                this.scheduleCronModel.months = [1];
            }
        }
        this.emitScheduleFromModel();
    },

    scheduleDowIsStar() {
        return this.scheduleCronModel.dow === '*';
    },

    scheduleDowIsOn(uiIndex) {
        const cron = this.scheduleWeekdays[uiIndex].cron;
        const part = this.scheduleCronModel.dow;
        if (part === '*') return true;
        return part.includes(cron);
    },

    scheduleToggleDow(uiIndex) {
        const cron = this.scheduleWeekdays[uiIndex].cron;
        const min = 1;
        const max = 7;
        let part = this.scheduleCronModel.dow;
        let set;
        if (part === '*') {
            set = new Set();
            for (let i = min; i <= max; i += 1) set.add(i);
        } else {
            set = new Set(part);
        }
        if (set.has(cron)) set.delete(cron);
        else set.add(cron);
        if (set.size === 0) {
            this.scheduleCronModel.dow = [2];
        } else if (set.size === max) {
            this.scheduleCronModel.dow = '*';
        } else {
            this.scheduleCronModel.dow = [...set].sort((a, b) => a - b);
        }
        this.emitScheduleFromModel();
    },

    scheduleSetDowStar(starred) {
        if (starred) {
            this.scheduleCronModel.dow = '*';
        } else {
            const cur = this.scheduleCronModel.dow;
            if (cur === '*' || !Array.isArray(cur) || cur.length === 0) {
                this.scheduleCronModel.dow = [2];
            }
        }
        this.emitScheduleFromModel();
    },

    scheduleYearIsStar() {
        return this.scheduleCronModel.years === '*';
    },

    scheduleSetYearStar(starred) {
        if (starred) {
            this.scheduleCronModel.years = '*';
        } else {
            const cur = this.scheduleCronModel.years;
            let y = new Date().getFullYear();
            if (Array.isArray(cur) && cur.length === 1) y = cur[0];
            this.scheduleCronModel.years = [y];
        }
        this.emitScheduleFromModel();
    },

    scheduleYearSingleDisplay() {
        const y = this.scheduleCronModel.years;
        if (y === '*') return new Date().getFullYear();
        if (Array.isArray(y) && y.length >= 1) return y[0];
        return new Date().getFullYear();
    },

    scheduleApplyYearSingle(v) {
        let n = parseInt(v, 10);
        if (Number.isNaN(n)) return;
        n = Math.min(2099, Math.max(1970, n));
        this.scheduleCronModel.years = [n];
        this.emitScheduleFromModel();
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
        this.$nextTick(() => this.syncScheduleFromInput());
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
        this.$nextTick(() => this.syncScheduleFromInput());
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