import { promises as fs } from 'fs';
import { resolve } from 'path';
import { execa } from 'execa';
export async function getIsPackageInstalled(parameters) {
    const { packageName, cwd = process.cwd() } = parameters;
    try {
        const packageManager = await getPackageManager();
        const command = packageManager === 'yarn' ? ['why', packageName] : ['ls', packageName];
        const { stdout } = await execa(packageManager, command, { cwd });
        if (stdout !== '')
            return true;
        return false;
    }
    catch (_error) {
        return false;
    }
}
export async function getPackageManager(executable) {
    const userAgent = process.env.npm_config_user_agent;
    if (userAgent) {
        if (userAgent.includes('pnpm'))
            return 'pnpm';
        // The yarn@^3 user agent includes npm, so yarn must be checked first.
        if (userAgent.includes('yarn'))
            return 'yarn';
        if (userAgent.includes('npm'))
            return executable ? 'npx' : 'npm';
    }
    const packageManager = await detect();
    if (packageManager === 'npm' && executable)
        return 'npx';
    return packageManager;
}
async function detect(parameters = {}) {
    const { cwd, includeGlobalBun } = parameters;
    const type = await getTypeofLockFile(cwd);
    if (type) {
        return type;
    }
    const [hasYarn, hasPnpm, hasBun] = await Promise.all([
        hasGlobalInstallation('yarn'),
        hasGlobalInstallation('pnpm'),
        includeGlobalBun && hasGlobalInstallation('bun'),
    ]);
    if (hasYarn)
        return 'yarn';
    if (hasPnpm)
        return 'pnpm';
    if (hasBun)
        return 'bun';
    return 'npm';
}
const cache = new Map();
function hasGlobalInstallation(pm) {
    const key = `has_global_${pm}`;
    if (cache.has(key)) {
        return Promise.resolve(cache.get(key));
    }
    return execa(pm, ['--version'])
        .then((res) => {
        return /^\d+.\d+.\d+$/.test(res.stdout);
    })
        .then((value) => {
        cache.set(key, value);
        return value;
    })
        .catch(() => false);
}
function getTypeofLockFile(cwd = '.') {
    const key = `lockfile_${cwd}`;
    if (cache.has(key)) {
        return Promise.resolve(cache.get(key));
    }
    return Promise.all([
        pathExists(resolve(cwd, 'yarn.lock')),
        pathExists(resolve(cwd, 'package-lock.json')),
        pathExists(resolve(cwd, 'pnpm-lock.yaml')),
        pathExists(resolve(cwd, 'bun.lockb')),
    ]).then(([isYarn, isNpm, isPnpm, isBun]) => {
        let value = null;
        if (isYarn)
            value = 'yarn';
        else if (isPnpm)
            value = 'pnpm';
        else if (isBun)
            value = 'bun';
        else if (isNpm)
            value = 'npm';
        cache.set(key, value);
        return value;
    });
}
async function pathExists(p) {
    try {
        await fs.access(p);
        return true;
    }
    catch {
        return false;
    }
}
//# sourceMappingURL=packages.js.map