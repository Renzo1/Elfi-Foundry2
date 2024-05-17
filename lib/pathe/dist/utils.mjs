import { k as normalizeWindowsPath, j as join } from './shared/pathe.92c04245.mjs';

const pathSeparators = /* @__PURE__ */ new Set(["/", "\\", void 0]);
const normalizedAliasSymbol = Symbol.for("pathe:normalizedAlias");
function normalizeAliases(_aliases) {
  if (_aliases[normalizedAliasSymbol]) {
    return _aliases;
  }
  const aliases = Object.fromEntries(
    Object.entries(_aliases).sort(([a], [b]) => _compareAliases(a, b))
  );
  for (const key in aliases) {
    for (const alias in aliases) {
      if (alias === key || key.startsWith(alias)) {
        continue;
      }
      if (aliases[key].startsWith(alias) && pathSeparators.has(aliases[key][alias.length])) {
        aliases[key] = aliases[alias] + aliases[key].slice(alias.length);
      }
    }
  }
  Object.defineProperty(aliases, normalizedAliasSymbol, {
    value: true,
    enumerable: false
  });
  return aliases;
}
function resolveAlias(path, aliases) {
  const _path = normalizeWindowsPath(path);
  aliases = normalizeAliases(aliases);
  for (const alias in aliases) {
    if (_path.startsWith(alias) && pathSeparators.has(_path[alias.length])) {
      return join(aliases[alias], _path.slice(alias.length));
    }
  }
  return _path;
}
const FILENAME_RE = /(^|[/\\])([^/\\]+?)(?=(\.[^.]+)?$)/;
function filename(path) {
  return path.match(FILENAME_RE)?.[2];
}
function _compareAliases(a, b) {
  return b.split("/").length - a.split("/").length;
}

export { filename, normalizeAliases, resolveAlias };
