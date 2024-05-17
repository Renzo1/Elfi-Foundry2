import { format as utilFormat } from 'util';
import ora from 'ora';
import pc from 'picocolors';
function format(args) {
    return utilFormat(...args)
        .split('\n')
        .join('\n');
}
export function success(...args) {
    console.log(pc.green(format(args)));
}
export function info(...args) {
    console.info(pc.blue(format(args)));
}
export function log(...args) {
    console.log(pc.white(format(args)));
}
export function warn(...args) {
    console.warn(pc.yellow(format(args)));
}
export function error(...args) {
    console.error(pc.red(format(args)));
}
export function spinner() {
    return ora({
        color: 'yellow',
        spinner: 'dots',
    });
}
//# sourceMappingURL=logger.js.map