export const jsonViewer = {
  renderValue(value, level = 0) {
    if (value === null || typeof value !== 'object') {
      return this.formatPrimitive(value);
    }

    if (Array.isArray(value)) {
      return this.renderArray(value, level);
    }

    return this.renderObject(value, level);
  },

  formatPrimitive(value) {
    if (typeof value === 'string') {
      return `<span class="text-blue-600">"${value}"</span>`;
    }
    if (typeof value === 'boolean') {
      return `<span class="text-blue-600">${value}</span>`;
    }
    if (value === null) {
      return `<span class="text-gray-500">null</span>`;
    }
    if (typeof value === 'number') {
      return `<span class="text-purple-500">${value}</span>`;
    }
    return `<span>${value}</span>`;
  },

  renderObject(obj, level) {
    const indent = '&nbsp;'.repeat(level * 4); // 4 space to level
    let html = '{<br>';

    const keys = Object.keys(obj);
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      const val = obj[key];

      const currentIndent = '&nbsp;'.repeat((level + 1) * 4);
      html += `${currentIndent}<span class="text-green-700">"${key}"</span>: ${this.renderValue(val, level + 1)}`;
      if (i < keys.length - 1) html += ',';
      html += '<br>';
    }

    const closingIndent = '&nbsp;'.repeat(level * 4);
    html += `${closingIndent}}`;
    return html;
  },

  renderArray(arr, level) {
    const indent = '&nbsp;'.repeat(level * 4);
    let html = '[<br>';

    for (let i = 0; i < arr.length; i++) {
      const val = arr[i];
      const itemIndent = '&nbsp;'.repeat((level + 1) * 4);
      html += `${itemIndent}${this.renderValue(val, level + 1)}`;
      if (i < arr.length - 1) html += ',';
      html += '<br>';
    }

    const closingIndent = '&nbsp;'.repeat(level * 4);
    html += `${closingIndent}]`;
    return html;
  },
};
