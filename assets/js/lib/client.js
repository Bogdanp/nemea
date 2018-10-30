function makeRequest(uri, options) {
  const params = new URLSearchParams();
  for (const param of Object.keys(options.params || {})) {
    params.append(param, options.params[param]);
  }
  params.sort();

  if (options.params) {
    uri += `?${params}`;
  }

  options.credentials = options.credentials || "same-origin";
  return fetch(uri, options);
}

function handleResponse(response) {
  if (response.status >= 400) {
    const error = new Error("Request error.");
    error.details = response;
    throw error;
  }

  return response.json();
}

export default function request(uri, options = {}) {
  return makeRequest(uri, options).then(handleResponse);
}
