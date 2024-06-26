import { homedir } from 'os';
import { default as fs } from 'fs-extra';
import { join } from 'pathe';
/** Fetches and parses contract ABIs from network resource with `fetch`. */
export function fetch(config) {
    const { cacheDuration = 1800000, contracts: contractConfigs, getCacheKey = ({ contract }) => JSON.stringify(contract), name = 'Fetch', parse = ({ response }) => response.json(), request, timeoutDuration = 5000, } = config;
    return {
        async contracts() {
            const cacheDir = join(homedir(), '.wagmi-cli/plugins/fetch/cache');
            await fs.ensureDir(cacheDir);
            const timestamp = Date.now() + cacheDuration;
            const contracts = [];
            for (const contract of contractConfigs) {
                const cacheKey = getCacheKey({ contract });
                const cacheFilePath = join(cacheDir, `${cacheKey}.json`);
                const cachedFile = await fs.readJSON(cacheFilePath).catch(() => null);
                let abi;
                if (cachedFile?.timestamp > Date.now())
                    abi = cachedFile.abi;
                else {
                    try {
                        const controller = new globalThis.AbortController();
                        const timeout = setTimeout(() => controller.abort(), timeoutDuration);
                        const { url, init } = await request(contract);
                        const response = await globalThis.fetch(url, {
                            ...init,
                            signal: controller.signal,
                        });
                        clearTimeout(timeout);
                        abi = await parse({ response });
                        await fs.writeJSON(cacheFilePath, { abi, timestamp });
                    }
                    catch (error) {
                        try {
                            // Attempt to read from cache if fetch fails.
                            abi = (await fs.readJSON(cacheFilePath)).abi;
                        }
                        catch { }
                        if (!abi)
                            throw error;
                    }
                }
                contracts.push({ abi, address: contract.address, name: contract.name });
            }
            return contracts;
        },
        name,
    };
}
//# sourceMappingURL=fetch.js.map