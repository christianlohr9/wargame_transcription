const http = require('http');
const log = require('electron-log');

/** Possible health states */
const HealthState = {
  STARTING: 'starting',
  HEALTHY: 'healthy',
  UNHEALTHY: 'unhealthy',
  STOPPED: 'stopped',
};

/**
 * Default service health configurations.
 */
const DEFAULT_SERVICES = [
  { name: 'backend', healthUrl: 'http://localhost:8081/actuator/health', interval: 5000 },
  { name: 'diarization', healthUrl: 'http://localhost:8082/health', interval: 5000 },
  { name: 'chat', healthUrl: 'http://localhost:8083/health', interval: 5000 },
];

class HealthChecker {
  /**
   * @param {Array<{name: string, healthUrl: string, interval?: number}>} [services]
   */
  constructor(services) {
    this.services = services || DEFAULT_SERVICES;
    /** @type {Map<string, string>} service name -> HealthState */
    this.status = new Map();
    /** @type {Map<string, NodeJS.Timeout>} */
    this._intervals = new Map();
    /** @type {function|null} */
    this._onChange = null;

    /** @type {Map<string, number>} tracks when 'starting' began */
    this._startingAt = new Map();

    for (const svc of this.services) {
      this.status.set(svc.name, HealthState.STOPPED);
    }
  }

  /**
   * Begin polling all services.
   */
  start() {
    for (const svc of this.services) {
      // Poll immediately, then on interval — state stays 'stopped' until a response arrives
      this._poll(svc);
      const id = setInterval(() => this._poll(svc), svc.interval || 5000);
      this._intervals.set(svc.name, id);
    }
  }

  /**
   * Stop all polling.
   */
  stop() {
    for (const [name, id] of this._intervals) {
      clearInterval(id);
    }
    this._intervals.clear();
  }

  /**
   * Get current status of all services.
   * @returns {Record<string, string>}
   */
  getStatus() {
    const result = {};
    for (const [name, state] of this.status) {
      result[name] = state;
    }
    return result;
  }

  /**
   * Register a callback fired on status transitions.
   * @param {function} callback - receives full status Record
   */
  onStatusChange(callback) {
    this._onChange = callback;
  }

  /**
   * Manually set a service state (e.g. to 'starting' when process is spawned).
   * @param {string} name
   * @param {string} state - one of HealthState values
   */
  setState(name, state) {
    this._setState(name, state);
  }

  /**
   * Poll a single service's health endpoint.
   * @param {{name: string, healthUrl: string}} svc
   * @private
   */
  _poll(svc) {
    const url = new URL(svc.healthUrl);
    const options = {
      hostname: url.hostname,
      port: url.port,
      path: url.pathname,
      method: 'GET',
      timeout: 3000,
    };

    const req = http.request(options, (res) => {
      if (res.statusCode >= 200 && res.statusCode < 300) {
        this._setState(svc.name, HealthState.HEALTHY);
      } else {
        this._setState(svc.name, HealthState.UNHEALTHY);
      }
      // Consume body to free resources
      res.resume();
    });

    req.on('error', () => {
      // Connection refused or timeout — service is unreachable
      const current = this.status.get(svc.name);
      if (current === HealthState.STOPPED) {
        // Not expected to be running — stay stopped
        return;
      }
      if (current === HealthState.STARTING) {
        // Keep starting state, but timeout after 60s
        const startedAt = this._startingAt.get(svc.name) || Date.now();
        if (Date.now() - startedAt > 60000) {
          this._setState(svc.name, HealthState.UNHEALTHY);
        }
        return;
      }
      this._setState(svc.name, HealthState.UNHEALTHY);
    });

    req.on('timeout', () => {
      req.destroy();
    });

    req.end();
  }

  /**
   * Update state and fire callback on transitions.
   * @param {string} name
   * @param {string} newState
   * @private
   */
  _setState(name, newState) {
    const prev = this.status.get(name);
    if (prev !== newState) {
      log.info(`Health [${name}]: ${prev} -> ${newState}`);
      this.status.set(name, newState);
      if (newState === HealthState.STARTING) {
        this._startingAt.set(name, Date.now());
      } else {
        this._startingAt.delete(name);
      }
      if (this._onChange) {
        this._onChange(this.getStatus());
      }
    }
  }
}

module.exports = { HealthChecker, HealthState, DEFAULT_SERVICES };
