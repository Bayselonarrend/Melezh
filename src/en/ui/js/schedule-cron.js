/**
 * Рawithшandренный cron Chronos / rust `cron`: 7 toлей
 * «sec min hr day_меwith month day_notdелand year»
 * Днand notdелand in dinandжtoе: handwithлa 1–7, ydе 1 = inwith, 2 = пн … 7 = withб (withм. days_of_week in crate cron).
 * Todпandwithand dnotй notdелand in UI fordaютwithя in scheduler-view (Пн…Inwith → те же oрdandtoлы).
 */

/** @typedef {{ seconds: '*'|number[], minutes: '*'|number[], hours: '*'|number[], dom: '*'|number[], months: '*'|number[], dow: '*'|number[], years: '*'|number[], raw?: string }} ScheduleFormModel */

/** @returns {ScheduleFormModel} */
export function defaultScheduleModel() {
    return {
        seconds: [0],
        minutes: [0],
        hours: [9],
        dom: '*',
        months: '*',
        dow: '*',
        years: '*',
    };
}

/**
 * Прowithтые fields: *, single number, withпandwithtoand and dandaпaзheы from цandфр.
 * Без шayoin /, without andмён monthеin, without L # ?
 */
export function cronFieldSupportsConstructor(token) {
    const t = String(token ?? '').trim();
    if (!t) return false;
    if (/[a-z]/i.test(t)) return false;
    if (t.includes('/') || t.includes('L') || t.includes('#') || t === '?') return false;
    return /^[\d,\-\*]+$/.test(t);
}

/**
 * @param {string} token
 * @param {number} min
 * @param {number} max
 * @returns {{ all: boolean, values: number[] }|null}
 */
export function expandSimpleCronField(token, min, max) {
    const t = String(token ?? '').trim();
    if (!cronFieldSupportsConstructor(t)) return null;
    if (t === '*') return { all: true, values: [] };

    const parts = t.split(',');
    const values = new Set();

    for (const partRaw of parts) {
        const part = partRaw.trim();
        if (!part) return null;

        if (part.includes('-')) {
            const [a, b] = part.split('-');
            const lo = Number(a);
            const hi = Number(b);
            if (!Number.isInteger(lo) || !Number.isInteger(hi)) return null;
            if (lo > hi || lo < min || hi > max) return null;
            for (let v = lo; v <= hi; v += 1) values.add(v);
        } else {
            const v = Number(part);
            if (!Number.isInteger(v) || v < min || v > max) return null;
            values.add(v);
        }
    }

    const sorted = [...values].sort((x, y) => x - y);
    const fullSpan = sorted.length === max - min + 1
        && sorted[0] === min
        && sorted[sorted.length - 1] === max;

    return { all: fullSpan, values: sorted };
}

/**
 * @param {number[]} values sorted unique
 * @param {number} min
 * @param {number} max
 */
export function serializeSimpleField(values, min, max) {
    const v = [...new Set(values)].filter(n => Number.isInteger(n)).sort((a, b) => a - b);
    if (!v.length) return '*';

    const isAll = v.length === max - min + 1 && v[0] === min && v[v.length - 1] === max;
    if (isAll) return '*';

    const chunks = [];
    let i = 0;
    while (i < v.length) {
        let j = i;
        while (j + 1 < v.length && v[j + 1] === v[j] + 1) j += 1;
        if (j > i) chunks.push(`${v[i]}-${v[j]}`);
        else chunks.push(String(v[i]));
        i = j + 1;
    }
    return chunks.join(',');
}

/**
 * @param {string} str
 * @returns {{ ok: true, model: ScheduleFormModel } | { ok: false, reason: string }}
 */
export function tryParseScheduleString(str) {
    const trimmed = String(str ?? '').trim();
    const parts = trimmed.split(/\s+/).filter(Boolean);
    if (parts.length !== 7) return { ok: false, reason: 'Nужbut рoinbut 7 toлей hерез прaboutел.' };

    const [secT, minT, hourT, domT, monT, dowT, yearT] = parts;

    const sec = expandSimpleCronField(secT, 0, 59);
    const minu = expandSimpleCronField(minT, 0, 59);
    const hour = expandSimpleCronField(hourT, 0, 23);
    const dom = expandSimpleCronField(domT, 1, 31);
    const months = expandSimpleCronField(monT, 1, 12);
    const dow = expandSimpleCronField(dowT, 1, 7);

    let yearsPart;
    if (yearT === '*') {
        yearsPart = '*';
    } else {
        const y = expandSimpleCronField(yearT, 1970, 2099);
        if (!y) {
            return {
                ok: false,
                reason: 'Schedule уwithтabutinлеbut inруhную',
            };
        }
        yearsPart = y.all ? '*' : y.values;
    }

    if (!sec || !minu || !hour || !dom || !months || !dow) {
        return {
            ok: false,
            reason: 'Schedule уwithтabutinлеbut inруhную',
        };
    }

    /** @returns {'*'|number[]} */
    const wrap = (e) => (e.all ? '*' : e.values);

    return {
        ok: true,
        model: {
            seconds: wrap(sec),
            minutes: wrap(minu),
            hours: wrap(hour),
            dom: wrap(dom),
            months: wrap(months),
            dow: wrap(dow),
            years: yearsPart,
            raw: trimmed,
        },
    };
}

/**
 * @param {ScheduleFormModel} model
 */
export function buildScheduleString(model) {
    const secStr = serializeTimePart(model.seconds, 0, 59);
    const minStr = serializeTimePart(model.minutes, 0, 59);
    const hourStr = serializeTimePart(model.hours, 0, 23);
    const domStr = serializeTimePart(model.dom, 1, 31);
    const monStr = serializeTimePart(model.months, 1, 12);
    const dowStr = serializeTimePart(model.dow, 1, 7);
    const yeStr = model.years === '*' ? '*' : serializeSimpleField(/** @type {number[]} */(model.years), 1970, 2099);

    return [secStr, minStr, hourStr, domStr, monStr, dowStr, yeStr].join(' ');
}

/**
 * @param {'*'|number[]} part
 */
function serializeTimePart(part, min, max) {
    if (part === '*') return '*';
    return serializeSimpleField(part, min, max);
}
