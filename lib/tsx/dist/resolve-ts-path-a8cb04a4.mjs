import o from"path";const s=Object.create(null);s[".js"]=[".ts",".tsx",".js",".jsx"],s[".jsx"]=[".tsx",".ts",".jsx",".js"],s[".cjs"]=[".cts"],s[".mjs"]=[".mts"];const i=t=>{const x=o.extname(t),[c,e]=o.extname(t).split("?"),n=s[c];if(n){const r=t.slice(0,-x.length);return n.map(j=>r+j+(e?`?${e}`:""))}};export{i as r};