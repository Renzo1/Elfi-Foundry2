import l from"path";import S from"fs";import m from"module";import{parseTsconfig as j,getTsconfig as E,createFilesMatcher as x,createPathsMatcher as y}from"get-tsconfig";import{i as O,c}from"../source-map-53867ec2.mjs";import{a as N,b as P}from"../index-915aae05.mjs";import{r as g}from"../resolve-ts-path-a8cb04a4.mjs";import"source-map-support";import"url";import"esbuild";import"crypto";import"os";const b=/^\.{1,2}\//,A=/\.[cm]?tsx?$/,M=`${l.sep}node_modules${l.sep}`,a=process.env.ESBK_TSCONFIG_PATH?{path:l.resolve(process.env.ESBK_TSCONFIG_PATH),config:j(process.env.ESBK_TSCONFIG_PATH)}:E(),_=a&&x(a),T=a&&y(a),v=O(),R=c([13,2,0])>=0||c([12,20,0])>=0&&c([13,0,0])<0,f=m._extensions,I=f[".js"],C=[".js",".cjs",".cts",".mjs",".mts",".ts",".tsx",".jsx"],F=(o,s)=>{if(!C.some(t=>s.endsWith(t)))return I(o,s);process.send&&process.send({type:"dependency",path:s});let e=S.readFileSync(s,"utf8");if(s.endsWith(".cjs")&&R){const t=N(s,e);t&&(e=v(t,s))}else{const t=P(e,s,{tsconfigRaw:_==null?void 0:_(s)});e=v(t,s)}o._compile(e,s)};[".js",".ts",".tsx",".jsx"].forEach(o=>{f[o]=F}),Object.defineProperty(f,".mjs",{value:F,enumerable:!1});const D=c([16,0,0])>=0||c([14,18,0])>=0,d=m._resolveFilename.bind(m);m._resolveFilename=(o,s,r,e)=>{var t;if(!D&&o.startsWith("node:")&&(o=o.slice(5)),T&&!b.test(o)&&!((t=s==null?void 0:s.filename)!=null&&t.includes(M))){const i=T(o);for(const p of i){const u=h(p,s,r,e);if(u)return u;try{return d(p,s,r,e)}catch{}}}const n=h(o,s,r,e);return n||d(o,s,r,e)};const h=(o,s,r,e)=>{const t=g(o);if(s!=null&&s.filename&&A.test(s.filename)&&t)try{return d(t[0],s,r,e)}catch(n){const{code:i}=n;if(i!=="MODULE_NOT_FOUND"&&i!=="ERR_PACKAGE_PATH_NOT_EXPORTED")throw n}};