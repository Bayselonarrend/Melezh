export async function handleFetchResponse(response) {
  const contentType = response.headers.get('content-type');

  let data;
  try {
    if (contentType && contentType.includes('application/json')) {
      data = await response.json();
    } else {
      data = null;
    }
  } catch (e) {
    data = null;
  }

  // Если сервер вернул JSON с { result: false, error: ... }
  if (data && !data.result) {
    return { success: false, message: data.error || 'Неизвестная ошибка', data: data };
  }

  // Обычная сетевая ошибка без JSON
  if (!response.ok) {
    return {
      success: false,
      message: `Ошибка сети ${response.status} ${response.statusText}`,
      data: null
    };
  }

if (data != null) {
  if (data.data !== undefined) {
    data = data.data;
  }
}

  // Успех
  return {
    success: true,
    data: data ?? null
  };
}