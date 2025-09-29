import { handleFetchResponse } from '#melezh_base_path#js/error-fetch.js';

let editorInstance = null; // <-- вне export

export const codeEditorView = () => ({
    // editor: null, // <-- убрать из Alpine data
    code: '',
    fileName: null,
    isSaving: false,
    error: '',
    _isInitialized: false,

    async init() {
        if (this._isInitialized) return;
        this._isInitialized = true;

        const match = window.location.hash.match(/[?&]file=([^&]*)/);
        this.fileName = match ? decodeURIComponent(match[1]) : null;

        if (!this.fileName) {
            this.error = 'Не указан файл';
            return;
        }

        await this.loadMonaco();
        await this.loadCode();
    },

    loadMonaco() {
        return new Promise((resolve, reject) => {
            if (window.monaco) {
                this.registerBSLLanguage();
                this.registerBSLCompletionProvider();
                resolve();
                return;
            }

            require(['vs/editor/editor.main'], () => {
                this.registerBSLLanguage();
                this.registerBSLCompletionProvider();
                resolve();
            }, reject);
        });
    },

    async loadCode() {
        try {
            if (editorInstance != null){
                return;
            };

            this.$refs.container.innerHTML = '';

            const url = `api/getText?file=${encodeURIComponent(this.fileName)}`;
            const res = await fetch(url);
            const data = await res.json();

            if (!data.result) throw new Error(data.error || 'Ошибка загрузки');

            this.code = data.text || '';

            editorInstance = monaco.editor.create(this.$refs.container, {
                value: this.code,
                language: 'bsl',
                theme: 'vs',
                automaticLayout: true,
                minimap: { enabled: true },
                tabSize: 4,
                insertSpaces: true,
                fontSize: 14,
                scrollBeyondLastLine: false,
                wordWrap: 'off'
            });


        } catch (err) {
            console.error('Ошибка:', err);
            this.error = `Ошибка: ${err.message}`;
            window.dispatchEvent(new CustomEvent('show-error', { detail: { message: this.error } }));
        }
    },

    async save() {
        if (!this.fileName) return;

        this.isSaving = true;
        this.error = '';

        try {
            const text = editorInstance.getValue(); // используем editorInstance

            const res = await fetch('api/saveText', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ file: this.fileName, code: text })
            });

            const result = await handleFetchResponse(res);
            if (!result.success) throw new Error(result.message);

            window.dispatchEvent(new CustomEvent('show-success', { detail: { message: 'Сохранено' } }));
        } catch (err) {
            this.error = `Ошибка: ${err.message}`;
            window.dispatchEvent(new CustomEvent('show-error', { detail: { message: this.error } }));
        } finally {
            this.isSaving = false;
        }
    },

    destroy() {
        this._isInitialized = false;
        if (editorInstance && typeof editorInstance.dispose === 'function') {
            editorInstance.dispose();
            editorInstance = null;
        }
    },

    registerBSLLanguage() {
        if (monaco.languages.getLanguages().some(lang => lang.id === 'bsl')) return;

        monaco.languages.register({ id: 'bsl' });

        monaco.languages.setMonarchTokensProvider('bsl', {
            tokenizer: {
                root: [
                    [/\/\/.*/, 'comment'],

                    [/"/, { token: 'string.quote', bracket: '@open', next: '@stringDouble' }],

                    [/'\d{8}'/, 'number.date'],

                    [/&[a-zа-яё_]\w*/, 'annotation'],

                    [/\b(Процедура|Функция|КонецПроцедуры|КонецФункции|Если|Тогда|Иначе|ИначеЕсли|КонецЕсли|Пока|Цикл|КонецЦикла|Для|Каждого|Из|По|Выполнить|Попытка|Исключение|КонецПопытки|Возврат|Перем|Знач|Экспорт|Новый|Прервать|ВызватьИсключение|Неопределено|Истина|Ложь)\b/i, 'keyword'],
                    [/\b(Procedure|Function|EndProcedure|EndFunction|If|Then|Else|ElsIf|EndIf|While|Do|EndDo|For|Each|In|To|Execute|Try|Except|EndTry|Return|Var|Val|Export|New|Break|Raise|Undefined|True|False)\b/i, 'keyword'],

                    [/\b(Сообщить|Message|Предупреждение|DoMessageBox|СтрЗаменить|StrReplace|НСтр|NStr|Формат|Format|ТекущаяДата|CurrentDate|Новый|New|ПустаяСтрока|IsBlankString|Тип|Type|Число|Number|Строка|String|Дата|Date)\b/i, 'support.function'],

                    [/\b\d+(\.\d+)?\b/, 'number'],

                    [/[-+*/=<>!&|?:]/, 'operator'],

                    [/[{}()\[\]]/, '@brackets'],
                    [/[,;]/, 'delimiter'],

                    [/[a-zа-яё_]\w*/i, 'identifier']
                ],

                stringDouble: [
                    [/""/, 'string.escape'], // ""
                    [/"/, { token: 'string.quote', bracket: '@close', next: '@pop' }], // "
                    [/[^"]+/, 'string']
                ]
            }
        });

        monaco.languages.setLanguageConfiguration('bsl', {
            comments: { lineComment: '//' },
            brackets: [['{', '}'], ['[', ']'], ['(', ')']],
            autoClosingPairs: [
                { open: '"', close: '"' },
                { open: "'", close: "'" },
                { open: '(', close: ')' },
                { open: '[', close: ']' },
                { open: '{', close: '}' }
            ],
            surroundingPairs: [
                { open: '"', close: '"' },
                { open: "'", close: "'" },
                { open: '(', close: ')' },
                { open: '[', close: ']' },
                { open: '{', close: '}' }
            ]
        });
    },

    registerBSLCompletionProvider() {
        if (this._completionRegistered) return;
        this._completionRegistered = true;

        // Все списки выше — вставьте их здесь или импортируйте
        const allSuggestions = [
            ...BSL_KEYWORDS.map(label => ({
                label,
                kind: monaco.languages.CompletionItemKind.Keyword,
                insertText: label,
                range: null // будет установлен динамически
            })),
            ...BSL_FUNCTIONS.map(label => ({
                label,
                kind: monaco.languages.CompletionItemKind.Function,
                insertText: `${label}($0)`,
                insertTextRules: monaco.languages.CompletionItemInsertTextRule.InsertAsSnippet,
                range: null
            })),
            ...BSL_GLOBAL_OBJECTS.map(label => ({
                label,
                kind: monaco.languages.CompletionItemKind.Variable,
                insertText: label,
                range: null
            })),
            ...BSL_CONSTANTS.map(label => ({
                label,
                kind: monaco.languages.CompletionItemKind.Constant,
                insertText: label,
                range: null
            }))
        ];

        monaco.languages.registerCompletionItemProvider('bsl', {
            triggerCharacters: ['.', ' ', '('],
            provideCompletionItems: (model, position) => {
                const word = model.getWordUntilPosition(position);
                const range = {
                    startLineNumber: position.lineNumber,
                    endLineNumber: position.lineNumber,
                    startColumn: word.startColumn,
                    endColumn: word.endColumn
                };

                // Обновляем range для всех подсказок
                const suggestions = allSuggestions.map(s => ({
                    ...s,
                    range: range
                }));

                // Фильтрация по введённому тексту (регистронезависимо)
                const wordLower = word.word.toLowerCase();
                const filtered = suggestions.filter(s =>
                    s.label.toLowerCase().startsWith(wordLower)
                );

                return { suggestions: filtered };
            }
        });
    },

    destroy() {
        this._isInitialized = false;
        if (editorInstance && typeof editorInstance.dispose === 'function') {
            editorInstance.dispose();
            editorInstance = null;
        }
    }
});


const BSL_KEYWORDS = [
    // Управляющие конструкции
    'Процедура', 'Procedure', 'Функция', 'Function',
    'КонецПроцедуры', 'EndProcedure', 'КонецФункции', 'EndFunction',
    'Если', 'If', 'Тогда', 'Then', 'Иначе', 'Else', 'ИначеЕсли', 'ElsIf', 'КонецЕсли', 'EndIf',
    'Пока', 'While', 'Цикл', 'Do', 'КонецЦикла', 'EndDo',
    'Для', 'For', 'Каждого', 'Each', 'Из', 'In', 'По', 'To', 'Выполнить', 'Execute',
    'Попытка', 'Try', 'Исключение', 'Except', 'КонецПопытки', 'EndTry',
    'Возврат', 'Return', 'Перем', 'Var', 'Знач', 'Val', 'Экспорт', 'Export',
    'Прервать', 'Break', 'Продолжить', 'Continue',
    'ВызватьИсключение', 'Raise',
    'Не', 'NOT', 'И', 'AND', 'ИЛИ', 'OR'
];

const BSL_FUNCTIONS = [
    // Работа со строками
    'СтрДлина', 'StrLen', 'СокрЛ', 'TrimL', 'СокрП', 'TrimR', 'СокрЛП', 'TrimAll',
    'Лев', 'Left', 'Прав', 'Right', 'Сред', 'Mid', 'СтрНайти', 'StrFind',
    'ВРег', 'Upper', 'НРег', 'Lower', 'ТРег', 'Title',
    'Символ', 'Char', 'КодСимвола', 'CharCode',
    'ПустаяСтрока', 'IsBlankString', 'СтрЗаменить', 'StrReplace',
    'СтрЧислоСтрок', 'StrLineCount', 'СтрПолучитьСтроку', 'StrGetLine',
    'СтрЧислоВхождений', 'StrOccurrenceCount', 'СтрСравнить', 'StrCompare',
    'СтрНачинаетсяС', 'StrStartWith', 'СтрЗаканчиваетсяНа', 'StrEndsWith',
    'СтрРазделить', 'StrSplit', 'СтрСоединить', 'StrConcat',

    // Числа
    'Цел', 'Int', 'Окр', 'Round', 'ACos', 'ASin', 'ATan', 'Cos', 'Exp', 'Log', 'Log10', 'Pow', 'Sin', 'Sqrt', 'Tan',

    // Дата
    'Год', 'Year', 'Месяц', 'Month', 'День', 'Day', 'Час', 'Hour', 'Минута', 'Minute', 'Секунда', 'Second',
    'НачалоГода', 'BegOfYear', 'НачалоДня', 'BegOfDay', 'НачалоКвартала', 'BegOfQuarter',
    'НачалоМесяца', 'BegOfMonth', 'НачалоМинуты', 'BegOfMinute', 'НачалоНедели', 'BegOfWeek', 'НачалоЧаса', 'BegOfHour',
    'КонецГода', 'EndOfYear', 'КонецДня', 'EndOfDay', 'КонецКвартала', 'EndOfQuarter',
    'КонецМесяца', 'EndOfMonth', 'КонецМинуты', 'EndOfMinute', 'КонецНедели', 'EndOfWeek', 'КонецЧаса', 'EndOfHour',
    'НеделяГода', 'WeekOfYear', 'ДеньГода', 'DayOfYear', 'ДеньНедели', 'WeekDay',
    'ТекущаяДата', 'CurrentDate', 'ДобавитьМесяц', 'AddMonth',

    // Типы и преобразования
    'Тип', 'Type', 'ТипЗнч', 'TypeOf',
    'Булево', 'Boolean', 'Число', 'Number', 'Строка', 'String', 'Дата', 'Date', 'Массив', 'Структура', 'Соответствие', 'Array', 'Map', 'Structure',

    // Интерактив
    'Сообщить', 'Message', 'Предупреждение', 'DoMessageBox', 'ПоказатьПредупреждение', 'ShowMessageBox',
    'Вопрос', 'DoQueryBox', 'ПоказатьВопрос', 'ShowQueryBox',
    'ОчиститьСообщения', 'ClearMessages', 'Состояние', 'Status', 'Сигнал', 'Beep',

    // Форматирование
    'Формат', 'Format', 'ЧислоПрописью', 'NumberInWords', 'НСтр', 'NStr', 'СтрШаблон', 'StrTemplate',

    // Файлы
    'ПолучитьИмяВременногоФайла', 'GetTempFileName', 'КопироватьФайл', 'FileCopy',

    // JSON / XML
    'ПрочитатьJSON', 'ReadJSON', 'ЗаписатьJSON', 'WriteJSON',
    'ПрочитатьXML', 'ReadXML', 'ЗаписатьXML', 'WriteXML',

    // Прочее
    'Мин', 'Min', 'Макс', 'Max', 'ОписаниеОшибки', 'ErrorDescription',
    'Base64Строка', 'Base64String', 'Base64Значение', 'Base64Value',
    'Новый', 'New'
];

const BSL_GLOBAL_OBJECTS = [
   
];

const BSL_CONSTANTS = [
    'Истина', 'True', 'Ложь', 'False', 'Неопределено', 'Undefined', 'NULL'
];