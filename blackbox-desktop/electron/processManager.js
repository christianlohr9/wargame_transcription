const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');
const log = require('electron-log');
const treeKill = require('tree-kill');

const isWindows = process.platform === 'win32';

/**
 * Resolve runtime paths for bundled (portable) or system-installed runtimes.
 * When bundled runtimes exist under resources/, use them; otherwise fall back
 * to expecting the tools on the system PATH.
 *
 * @param {string} basePath - The blackbox-desktop/ directory
 * @returns {object} Resolved paths for java, python, JAR, service cwds, models
 */
function resolveRuntimePaths(basePath) {
  const resourcesPath = basePath;

  const jreBin = path.join(resourcesPath, 'resources', 'runtime', 'java', 'bin',
    isWindows ? 'javaw.exe' : 'java');
  const pythonBin = path.join(resourcesPath, 'resources', 'runtime', 'python',
    isWindows ? 'python.exe' : path.join('bin', 'python'));
  const jarPath = path.join(resourcesPath, 'resources', 'app', 'blackbox.jar');

  const bundledDiarization = path.join(resourcesPath, 'resources', 'app', 'diarization');
  const bundledChat = path.join(resourcesPath, 'resources', 'app', 'chat');
  const modelsPath = path.join(resourcesPath, 'resources', 'models');

  return {
    java: fs.existsSync(jreBin) ? jreBin : (isWindows ? 'javaw.exe' : 'java'),
    python: fs.existsSync(pythonBin) ? pythonBin : (isWindows ? 'python.exe' : 'python3'),
    jarPath: fs.existsSync(jarPath) ? jarPath : 'blackbox.jar',
    diarizationCwd: fs.existsSync(bundledDiarization)
      ? bundledDiarization
      : path.join(resourcesPath, '..', 'speaker-diarization-service'),
    chatCwd: fs.existsSync(bundledChat)
      ? bundledChat
      : path.join(resourcesPath, '..', 'ask-chat-service'),
    modelsPath,
  };
}

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
    /** @type {object} Resolved runtime paths (bundled or system) */
    this.runtimePaths = resolveRuntimePaths(this.basePath);
    /** @type {Map<string, {process: ChildProcess|null, status: string, pid: number|null}>} */
    this.services = new Map();

    log.info('Runtime paths resolved:', JSON.stringify(this.runtimePaths, null, 2));

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

    // Resolve command, args, cwd, and env from bundled runtimes
    const rp = this.runtimePaths;
    let command, args, cwd;
    const env = { ...process.env };

    if (name === 'backend') {
      command = overrides.command || rp.java;
      args = overrides.args || ['-jar', rp.jarPath];
      cwd = overrides.cwd || this.basePath;
    } else if (name === 'diarization') {
      command = overrides.command || rp.python;
      args = overrides.args || definition.args;
      cwd = overrides.cwd || rp.diarizationCwd;
      // Point model caches at bundled models directory if it exists
      if (fs.existsSync(rp.modelsPath)) {
        env.HF_HOME = path.join(rp.modelsPath, 'huggingface');
        env.WHISPER_CACHE = path.join(rp.modelsPath, 'whisper');
      }
    } else if (name === 'chat') {
      command = overrides.command || rp.python;
      args = overrides.args || definition.args;
      cwd = overrides.cwd || rp.chatCwd;
    } else {
      command = overrides.command || definition.command;
      args = overrides.args || definition.args;
      cwd = overrides.cwd || this.basePath;
    }

    log.info(`Starting service ${name}: ${command} ${args.join(' ')} in ${cwd}`);

    try {
      const child = spawn(command, args, {
        cwd,
        env,
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

module.exports = { ProcessManager, SERVICE_DEFINITIONS, resolveRuntimePaths };
