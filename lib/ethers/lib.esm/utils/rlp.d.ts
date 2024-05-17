/**
 *  The [[link-rlp]] (RLP) encoding is used throughout Ethereum
 *  to serialize nested structures of Arrays and data.
 *
 *  @_subsection api/utils:Recursive-Length Prefix  [about-rlp]
 */
export { decodeRlp } from "./rlp-decode.js";
export { encodeRlp } from "./rlp-encode.js";
/**
 *  An RLP-encoded structure.
 */
export type RlpStructuredData = string | Array<RlpStructuredData>;
//# sourceMappingURL=rlp.d.ts.map