import { type Address } from 'viem';
import { type ContractConfig } from '../config.js';
import { type Evaluate } from '../types.js';
export type BlockExplorerConfig = {
    /**
     * API key for block explorer. Appended to the request URL as query param `&apikey=${apiKey}`.
     */
    apiKey?: string | undefined;
    /**
     * Base URL for block explorer.
     */
    baseUrl: string;
    /**
     * Duration in milliseconds to cache ABIs.
     *
     * @default 1_800_000 // 30m in ms
     */
    cacheDuration?: number | undefined;
    /**
     * Contracts to fetch ABIs for.
     */
    contracts: Evaluate<Omit<ContractConfig, 'abi'>>[];
    /**
     * Function to get address from contract config.
     */
    getAddress?: ((config: {
        address: NonNullable<ContractConfig['address']>;
    }) => Address) | undefined;
    /**
     * Name of source.
     */
    name?: ContractConfig['name'] | undefined;
};
/**
 * Fetches contract ABIs from block explorers, supporting `?module=contract&action=getabi` requests.
 */
export declare function blockExplorer(config: BlockExplorerConfig): {
    contracts: () => import("../types.js").MaybePromise<ContractConfig<number, undefined>[]>;
    name: string;
    run?: ((config: {
        contracts: {
            abi: import("abitype").Abi;
            address?: `0x${string}` | Record<number, `0x${string}`> | undefined;
            name: string;
            content: string;
            meta: {
                abiName: string;
                addressName?: string | undefined;
                configName?: string | undefined;
            };
        }[];
        isTypeScript: boolean;
        outputs: readonly {
            plugin: Pick<import("../config.js").Plugin, "name">;
            imports?: string | undefined;
            prepend?: string | undefined;
            content: string;
        }[];
    }) => import("../types.js").MaybePromise<{
        imports?: string | undefined;
        prepend?: string | undefined;
        content: string;
    }>) | undefined;
    validate?: (() => import("../types.js").MaybePromise<void>) | undefined;
    watch?: import("../config.js").Watch | undefined;
};
//# sourceMappingURL=blockExplorer.d.ts.map