type FindConfigParameters = {
    /** Config file name */
    config?: string;
    /** Config file directory */
    root?: string;
};
/**
 * Resolves path to wagmi CLI config file.
 */
export declare function findConfig(parameters?: FindConfigParameters): Promise<string | undefined>;
export {};
//# sourceMappingURL=findConfig.d.ts.map