# Installation
> `npm install --save @types/ethereumjs-abi`

# Summary
This package contains type definitions for ethereumjs-abi (https://github.com/ethereumjs/ethereumjs-abi).

# Details
Files were exported from https://github.com/DefinitelyTyped/DefinitelyTyped/tree/master/types/ethereumjs-abi.
## [index.d.ts](https://github.com/DefinitelyTyped/DefinitelyTyped/tree/master/types/ethereumjs-abi/index.d.ts)
````ts
/// <reference types="node" />

export function soliditySHA3(argTypes: string[], args: any[]): Buffer;
export function soliditySHA256(argTypes: string[], args: any[]): Buffer;
export function solidityRIPEMD160(argTypes: string[], args: any[]): Buffer;
export function eventID(name: string, types: string[]): Buffer;
export function methodID(name: string, types: string[]): Buffer;
export function simpleEncode(signature: string, ...args: any[]): Buffer;
export function simpleDecode(signature: string, data: Buffer): any[];
export function rawEncode(types: string[], values: any[]): Buffer;
export function rawDecode(types: string[], data: Buffer): any[];
export function stringify(types: string[], values: any[]): string;
export function solidityPack(types: string[], values: any[]): Buffer;
export function fromSerpent(signature: string): string[];
export function toSerpent(types: string[]): string;

````

### Additional Details
 * Last updated: Mon, 06 Nov 2023 22:41:05 GMT
 * Dependencies: [@types/node](https://npmjs.com/package/@types/node)

# Credits
These definitions were written by [Leonid Logvinov](https://github.com/LogvinovLeon), and [Artur Kozak](https://github.com/quezak).
