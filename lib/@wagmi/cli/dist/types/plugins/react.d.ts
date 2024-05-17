import { type Plugin } from '../config.js';
import { type Evaluate, type RequiredBy } from '../types.js';
export type ReactConfig = {
    getHookName?: 'legacy' | ((options: {
        contractName: string;
        itemName?: string | undefined;
        type: 'read' | 'simulate' | 'watch' | 'write';
    }) => `use${string}`);
};
type ReactResult = Evaluate<RequiredBy<Plugin, 'run'>>;
export declare function react(config?: ReactConfig): ReactResult;
export {};
//# sourceMappingURL=react.d.ts.map