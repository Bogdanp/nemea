export function duration(value) {
  const minutes = Math.floor(value / 60);
  const seconds = value % 60;

  return minutes ? `${minutes}m ${seconds}s` : `${seconds}s`;
}

export function numeric(value) {
  if (value > 1000000000) {
    return (value / 1000000000).toFixed(1) + "B";
  } else if (value > 1000000) {
    return (value / 1000000).toFixed(1) + "M";
  } else if (value > 1000) {
    return (value / 1000).toFixed(1) + "K";
  }

  return value;
}
