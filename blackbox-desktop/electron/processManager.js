const { spawn } = require('child_process');
const path = require('path');
const log = require('electron-log');
const treeKill = require('tree-kill');

const isWindows = process.platform === 'win32';

/**
 * Service definitions with platform-specific binary names.
 */
const SERVICE_DEFINITIONS = {
  backend: {
    command: isWindows ? 'javaw.exe' : 'java',
    args: ['-jar', 'blackbox.jar'],
    port: 8081,
    required: true,
  },
  diarization: {
    command: isWindows ? 'python.exe' : 'python3',
    args: ['-m', 'uvicorn', 'src.main:app', '--port', '8082'],
    port: 8082,
    required: false,
  },
  chat: {
    command: isWindows ? 'python.exe' : 'python3',
    args: ['-m', 'uvicorn', 'src.main:app', '--port', '8083'],
    port: 8083,
    required: false,
  },
};

class ProcessManager {
  constructor(basePath) {
    /** @type {string} Base path where service binaries/jars live */
    this.basePath = basePath || process.cwd();
    /** @type {Map<string, {process: ChildProcess|null, status: string, pid: number|null}>} */
    this.services = new Map();

    for (const name of Object.keys(SERVICE_DEFINITIONS)) {
      this.services.set(name, { process: null, status: 'stopped', pid: null });
    }
  }

  /**
   * Start a managed service by name.
   * @param {string} name - Service key from SERVICE_DEFINITIONS
   * @param {object} [overrides] - Optional overrides for command, args, cwd
   * @returns {boolean} true if started
   */
  startService(name, overrides = {}) {
    const definition = SERVICE_DEFINITIONS[name];
    if (!definition) {
      log.warn(`Unknown service: ${name}`);
      return false;
    }

    const entry = this.services.get(name);
    if (entry.status === 'running') {
      log.info(`Service ${name} is already running (pid ${entry.pid})`);
      return true;
    }

    const command = overrides.command || definition.command;
    const args = overrides.args || definition.args;
    const cwd = overrides.cwd || this.basePath;

    log.info(`Starting service ${name}: ${command} ${args.join(' ')} in ${cwd}`);

    try {
      const child = spawn(command, args, {
        cwd,
        windowsHide: true,
        stdio: ['ignore', 'pipe', 'pipe'],
      });

      child.stdout.on('data', (data) => {
        log.info(`[${name}:stdout] ${data.toString().trim()}`);
      });

      child.stderr.on('data', (data) => {
        log.warn(`[${name}:stderr] ${data.toString().trim()}`);
      });

      child.on('error', (err) => {
        log.error(`Service ${name} failed to start:`, err.message);
        this._updateStatus(name, 'error', null);
      });

      child.on('exit', (code, signal) => {
        log.info(`Service ${name} exited (code=${code}, signal=${signal})`);
        this._updateStatus(name, 'stopped', null);
      });

      this._updateStatus(name, 'running', child.pid);
      entry.process = child;

      return true;
    } catch (err) {
      log.error(`Failed to spawn ${name}:`, err.message);
      this._updateStatus(name, 'error', null);
      return false;
    }
  }

  /**
   * Gracefully stop a service via tree-kill (SIGTERM).
   * @param {string} name
   * @returns {Promise<void>}
   */
  stopService(name) {
    return new Promise((resolve) => {
      const entry = this.services.get(name);
      if (!entry || !entry.process || !entry.pid) {
        this._updateStatus(name, 'stopped', null);
        resolve();
        return;
      }

      log.info(`Stopping service ${name} (pid ${entry.pid})`);
      treeKill(entry.pid, 'SIGTERM', (err) => {
        if (err) {
          log.warn(`tree-kill error for ${name}:`, err.message);
        }
        entry.process = null;
        this._updateStatus(name, 'stopped', null);
        resolve();
      });
    });
  }

  /**
   * Stop all managed services.
   * @returns {Promise<void>}
   */
  async stopAll() {
    const names = [...this.services.keys()];
    await Promise.all(names.map((name) => this.stopService(name)));
  }

  /**
   * Get status of all services.
   * @returns {Record<string, {pid: number|null, status: string}>}
   */
  getStatus() {
    const result = {};
    for (const [name, entry] of this.services) {
      result[name] = { pid: entry.pid, status: entry.status };
    }
    return result;
  }

  /** @private */
  _updateStatus(name, status, pid) {
    const entry = this.services.get(name);
    if (entry) {
      entry.status = status;
      entry.pid = pid;
    }
    if (this._onStatusChange) {
      this._onStatusChange(this.getStatus());
    }
  }

  /**
   * Register a callback for status changes.
   * @param {function} callback
   */
  onStatusChange(callback) {
    this._onStatusChange = callback;
  }
}

module.exports = { ProcessManager, SERVICE_DEFINITIONS };
