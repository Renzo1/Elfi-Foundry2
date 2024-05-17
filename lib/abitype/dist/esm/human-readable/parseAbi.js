import { isStructSignature } from './runtime/signatures.js';
import { parseStructs } from './runtime/structs.js';
import { parseSignature } from './runtime/utils.js';
export function parseAbi(signatures) {
    const structs = parseStructs(signatures);
    const abi = [];
    const length = signatures.length;
    for (let i = 0; i < length; i++) {
        const signature = signatures[i];
        if (isStructSignature(signature))
            continue;
        abi.push(parseSignature(signature, structs));
    }
    return abi;
}
//# sourceMappingURL=parseAbi.js.map