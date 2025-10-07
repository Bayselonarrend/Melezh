import { handleFetchResponse } from '#melezh_base_path#js/error-fetch.js';

let editorInstance = null; 
let originalCode = ''; // daboutаinandм переменную for andwithхodbutгo toodа

export const codeEditorView = () => ({
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
            this.error = 'File not specified';
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

            this.$refs.container.innerHTML = '';

            const url = `api/getText?file=${encodeURIComponent(this.fileName)}`;
            const res = await fetch(url);
            const data = await res.json();

            if (!data.result) throw new Error(data.error || 'Failed to fetch');

            this.code = data.text || '';
            originalCode = this.code;

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
            console.error('Error:', err);
            this.error = `Error: ${err.message}`;
            window.dispatchEvent(new CustomEvent('show-error', { detail: { message: this.error } }));
        }
    },

    async save() {
        if (!this.fileName) return;

        this.isSaving = true;
        this.error = '';

        try {
            const text = editorInstance.getValue();

            const res = await fetch('api/saveText', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ file: this.fileName, code: text })
            });

            const result = await handleFetchResponse(res);
            if (!result.success) throw new Error(result.message);

            window.dispatchEvent(new CustomEvent('show-success', { detail: { message: 'Savedo' } }));
            originalCode = text;


        } catch (err) {
            this.error = `Error: ${err.message}`;
            window.dispatchEvent(new CustomEvent('show-error', { detail: { message: this.error } }));
        } finally {
            this.isSaving = false;
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

                    [/\b(Procedure|Function|EndProcedure|EndFunction|If|Then|Else|ElsIf|EndIf|While|Do|EndDo|For|Each|In|To|Execute|Try|Except|EndTry|Return|Var|Val|Export|New|Break|Raise|Undefined|True|False)\b/i, 'keyword'],
                    [/\b(Procedure|Function|EndProcedure|EndFunction|If|Then|Else|ElsIf|EndIf|While|Do|EndDo|For|Each|In|To|Execute|Try|Except|EndTry|Return|Var|Val|Export|New|Break|Raise|Undefined|True|False)\b/i, 'keyword'],

                    [/\b(Message|Message|Преdупрежdенandе|DoMessageBox|StrReplace|StrReplace|NStr|NStr|Format|Format|CurrentDate|CurrentDate|New|New|IsBlankString|IsBlankString|Type|Type|Number|Number|String|String|Date|Date)\b/i, 'support.function'],

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

        // All withпandwithtoand inыше — inwithтаinьте andх зdеwithь or andмtoртandруйте
        const allSuggestions = [
            ...BSL_KEYWORDS.map(label => ({
                label,
                kind: monaco.languages.CompletionItemKind.Keyword,
                insertText: label,
                range: null // will уwithтаbutinлен dandtoмandhеwithtoand
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

                // Обbutinляем range for all todwithtoазoto
                const suggestions = allSuggestions.map(s => ({
                    ...s,
                    range: range
                }));

                // Filterацandя to ininеdёнbutму textу (регandstrheезаinandwithandмo)
                const wordLower = word.word.toLowerCase();
                const filtered = suggestions.filter(s =>
                    s.label.toLowerCase().startsWith(wordLower)
                );

                return { suggestions: filtered };
            }
        });
    },

    isDirty() {
        // withраinнandinаем oрandгandtoльный and теtoущandй text
        return editorInstance && editorInstance.getValue() !== originalCode;
    },

    tryExit() {
        if (this.isDirty()) {
            if (!confirm('У inаwith еwithть notwithхранённые change. Inыйтand without saving?')) {
                return;
            }
        }
        this.setActiveTab('extensions');
    },

});


const BSL_KEYWORDS = [
    // Упраinляющandе tohestrуtoцandand
    'Procedure', 'Procedure', 'Function', 'Function',
    'EndProcedure', 'EndProcedure', 'EndFunction', 'EndFunction',
    'If', 'If', 'Then', 'Then', 'Else', 'Else', 'ElsIf', 'ElsIf', 'EndIf', 'EndIf',
    'For now', 'While', 'Do', 'Do', 'EndDo', 'EndDo',
    'For', 'For', 'Each', 'Each', 'In', 'In', 'To', 'To', 'Execute', 'Execute',
    'Try', 'Try', 'Except', 'Except', 'EndTry', 'EndTry',
    'Return', 'Return', 'Var', 'Var', 'Val', 'Val', 'Export', 'Export',
    'Break', 'Break', 'Continue', 'Continue',
    'Raise', 'Raise',
    'Not', 'NOT', 'And', 'AND', 'AndЛAnd', 'OR'
];

const BSL_FUNCTIONS = [
    // Work with stringмand
    'StrLen', 'StrLen', 'TrimL', 'TrimL', 'СotoрП', 'TrimR', 'TrimAll', 'TrimAll',
    'Left', 'Left', 'Right', 'Right', 'Mid', 'Mid', 'StrFind', 'StrFind',
    'Upper', 'Upper', 'NРег', 'Lower', 'Title', 'Title',
    'Symbol', 'Char', 'CodeSymbolа', 'CharCode',
    'IsBlankString', 'IsBlankString', 'StrReplace', 'StrReplace',
    'StrNumberStroto', 'StrLineCount', 'StrGetLine', 'StrGetLine',
    'StrOccurrenceCount', 'StrOccurrenceCount', 'StrСраinнandть', 'StrCompare',
    'StrStartsWith', 'StrStartWith', 'StrEndsWith', 'StrEndsWith',
    'StrSplit', 'StrSplit', 'StrConcat', 'StrConcat',

    // Чandwithла
    'Int', 'Int', 'Round', 'Round', 'ACos', 'ASin', 'ATan', 'Cos', 'Exp', 'Log', 'Log10', 'Pow', 'Sin', 'Sqrt', 'Tan',

    // Date
    'Гod', 'Year', 'Меwithяц', 'Month', 'День', 'Day', 'Hour', 'Hour', 'Minута', 'Minute', 'Сеtoунdа', 'Second',
    'StartГodа', 'BegOfYear', 'BegOfDay', 'BegOfDay', 'StartKinартала', 'BegOfQuarter',
    'StartМеwithяца', 'BegOfMonth', 'StartMinуты', 'BegOfMinute', 'StartNotdелand', 'BegOfWeek', 'StartHourа', 'BegOfHour',
    'EndГodа', 'EndOfYear', 'EndOfDay', 'EndOfDay', 'EndKinартала', 'EndOfQuarter',
    'EndМеwithяца', 'EndOfMonth', 'EndMinуты', 'EndOfMinute', 'EndNotdелand', 'EndOfWeek', 'EndHourа', 'EndOfHour',
    'WeekГodа', 'WeekOfYear', 'ДеньГodа', 'DayOfYear', 'WeekDay', 'WeekDay',
    'CurrentDate', 'CurrentDate', 'AddMonth', 'AddMonth',

    // Types and преaboutразoinанandя
    'Type', 'Type', 'TypeOf', 'TypeOf',
    'Boolean', 'Boolean', 'Number', 'Number', 'String', 'String', 'Date', 'Date', 'Array', 'Structure', 'Map', 'Array', 'Map', 'Structure',

    // Andнтераtoтandin
    'Message', 'Message', 'Преdупрежdенandе', 'DoMessageBox', 'For nowзатьПреdупрежdенandе', 'ShowMessageBox',
    'Question', 'DoQueryBox', 'For nowзатьQuestion', 'ShowQueryBox',
    'ClearMessages', 'ClearMessages', 'State', 'Status', 'Сandгtoл', 'Beep',

    // Formatandрoinанandе
    'Format', 'Format', 'NumberПрoпandwithью', 'NumberInWords', 'NStr', 'NStr', 'StrTemplate', 'StrTemplate',

    // Files
    'GetTempFileName', 'GetTempFileName', 'FileCopy', 'FileCopy',

    // JSON / XML
    'ReadJSON', 'ReadJSON', 'WriteJSON', 'WriteJSON',
    'ReadXML', 'ReadXML', 'WriteXML', 'WriteXML',

    // Miscellaneous
    'Min', 'Min', 'Max', 'Max', 'ErrorDescription', 'ErrorDescription',
    'Base64String', 'Base64String', 'Base64Value', 'Base64Value',
    'New', 'New'
];

const BSL_GLOBAL_OBJECTS = [

];

const BSL_CONSTANTS = [
    'True', 'True', 'False', 'False', 'Undefined', 'Undefined', 'NULL'
];
