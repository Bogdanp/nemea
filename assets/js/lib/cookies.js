export function parseCookies() {
  const cookies = {};
  const pair_re = /([^=]+)=([^;]+);?/g;

  let matches;
  while ((matches = pair_re.exec(document.cookie)) !== null) {
    const name = decodeURIComponent(matches[1].trim());
    const value = decodeURIComponent(matches[2].trim());
    cookies[name] = value;
  }

  return cookies;
}

export function deleteCookie(name) {
  document.cookie = `${name}=0; max-age=0`;
}
