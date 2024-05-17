import dedent from 'dedent';
import { execa, execaCommandSync } from 'execa';
import { default as fs } from 'fs-extra';
import { globby } from 'globby';
import { basename, extname, join, resolve } from 'pathe';
import pc from 'picocolors';
import { z } from 'zod';
import * as logger from '../logger.js';
const defaultExcludes = [
    'Common.sol/**',
    'Components.sol/**',
    'Script.sol/**',
    'StdAssertions.sol/**',
    'StdInvariant.sol/**',
    'StdError.sol/**',
    'StdCheats.sol/**',
    'StdMath.sol/**',
    'StdJson.sol/**',
    'StdStorage.sol/**',
    'StdUtils.sol/**',
    'Vm.sol/**',
    'console.sol/**',
    'console2.sol/**',
    'test.sol/**',
    '**.s.sol/*.json',
    '**.t.sol/*.json',
];
const FoundryConfigSchema = z.object({
    out: z.string().default('out'),
    src: z.string().default('src'),
});
/** Resolves ABIs from [Foundry](https://github.com/foundry-rs/foundry) project. */
export function foundry(config = {}) {
    const { artifacts, deployments = {}, exclude = defaultExcludes, forge: { clean = false, build = true, path: forgeExecutable = 'forge', rebuild = true, } = {}, include = ['*.json'], namePrefix = '', } = config;
    function getContractName(artifactPath, usePrefix = true) {
        const filename = basename(artifactPath);
        const extension = extname(artifactPath);
        return `${usePrefix ? namePrefix : ''}${filename.replace(extension, '')}`;
    }
    async function getContract(artifactPath) {
        const artifact = await fs.readJSON(artifactPath);
        return {
            abi: artifact.abi,
            address: deployments[getContractName(artifactPath, false)],
            name: getContractName(artifactPath),
        };
    }
    async function getArtifactPaths(artifactsDirectory) {
        return await globby([
            ...include.map((x) => `${artifactsDirectory}/**/${x}`),
            ...exclude.map((x) => `!${artifactsDirectory}/**/${x}`),
        ]);
    }
    const project = resolve(process.cwd(), config.project ?? '');
    let foundryConfig = {
        out: 'out',
        src: 'src',
    };
    try {
        foundryConfig = FoundryConfigSchema.parse(JSON.parse(execaCommandSync(`${forgeExecutable} config --json --root ${project}`)
            .stdout));
    }
    catch {
    }
    finally {
        foundryConfig = {
            ...foundryConfig,
            out: artifacts ?? foundryConfig.out,
        };
    }
    const artifactsDirectory = join(project, foundryConfig.out);
    return {
        async contracts() {
            if (clean)
                await execa(forgeExecutable, ['clean', '--root', project]);
            if (build)
                await execa(forgeExecutable, ['build', '--root', project]);
            if (!fs.pathExistsSync(artifactsDirectory))
                throw new Error('Artifacts not found.');
            const artifactPaths = await getArtifactPaths(artifactsDirectory);
            const contracts = [];
            for (const artifactPath of artifactPaths) {
                const contract = await getContract(artifactPath);
                if (!contract.abi?.length)
                    continue;
                contracts.push(contract);
            }
            return contracts;
        },
        name: 'Foundry',
        async validate() {
            // Check that project directory exists
            if (!(await fs.pathExists(project)))
                throw new Error(`Foundry project ${pc.gray(config.project)} not found.`);
            // Ensure forge is installed
            if (clean || build || rebuild)
                try {
                    await execa(forgeExecutable, ['--version']);
                }
                catch (_error) {
                    throw new Error(dedent `
            forge must be installed to use Foundry plugin.
            To install, follow the instructions at https://book.getfoundry.sh/getting-started/installation
          `);
                }
        },
        watch: {
            command: rebuild
                ? async () => {
                    logger.log(`${pc.magenta('Foundry')} Watching project at ${pc.gray(project)}`);
                    const subprocess = execa(forgeExecutable, [
                        'build',
                        '--watch',
                        '--root',
                        project,
                    ]);
                    subprocess.stdout?.on('data', (data) => {
                        process.stdout.write(`${pc.magenta('Foundry')} ${data}`);
                    });
                    process.once('SIGINT', shutdown);
                    process.once('SIGTERM', shutdown);
                    function shutdown() {
                        subprocess?.cancel();
                    }
                }
                : undefined,
            paths: [
                ...include.map((x) => `${artifactsDirectory}/**/${x}`),
                ...exclude.map((x) => `!${artifactsDirectory}/**/${x}`),
            ],
            async onAdd(path) {
                return getContract(path);
            },
            async onChange(path) {
                return getContract(path);
            },
            async onRemove(path) {
                return getContractName(path);
            },
        },
    };
}
//# sourceMappingURL=foundry.js.map