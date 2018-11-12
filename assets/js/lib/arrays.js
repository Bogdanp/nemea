export function arraysEqual(xs, ys) {
  return (
    xs.length == ys.length &&
    xs.reduce((acc, x, i) => {
      return acc && x === ys[i];
    }, true)
  );
}
