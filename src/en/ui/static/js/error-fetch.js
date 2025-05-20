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

  // If server inернул JSON with { result: false, error: ... }
  if (data && !data.result) {
    return { success: false, message: data.error || 'Notfromweightтtoя error', data: data };
  }

  // Обыhtoя withетеinая oшandбtoа without JSON
  if (!response.ok) {
    return {
      success: false,
      message: `Network error ${response.status} ${response.statusText}`,
      data: null
    };
  }

if (data != null) {
  if (data.data !== undefined) {
    data = data.data;
  }
}

  // Success
  return {
    success: true,
    data: data ?? null
  };
}
