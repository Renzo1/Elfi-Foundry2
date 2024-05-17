import { type Plugin } from '../config.js';
import { type Evaluate, type RequiredBy } from '../types.js';
export type ActionsConfig = {
    getActionName?: 'legacy' | ((options: {
        contractName: string;
        itemName?: string | undefined;
        type: 'read' | 'simulate' | 'watch' | 'write';
    }) => string);
    overridePackageName?: '@wagmi/core' | 'wagmi' | undefined;
};
type ActionsResult = Evaluate<RequiredBy<Plugin, 'run'>>;
export declare function actions(config?: ActionsConfig): ActionsResult;
export {};
//# sourceMappingURL=actions.d.ts.map