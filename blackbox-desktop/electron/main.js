const { app, BrowserWindow, ipcMain, protocol, net } = require('electron');
const path = require('path');
const fs = require('fs');
const os = require('os');
const log = require('electron-log');
const Store = require('electron-store');
const { ProcessManager } = require('./processManager');
const { HealthChecker } = require('./healthChecker');

// --- Settings Store ---
const settingsSchema = {
  llmBackend: { type: 'string', default: 'llamacpp' },
  ollamaEndpoint: { type: 'string', default: 'http://localhost:11434' },
  ollamaModel: { type: 'string', default: '' },
};

const store = new Store({
  schema: settingsSchema,
  defaults: {
    llmBackend: 'llamacpp',
    ollamaEndpoint: 'http://localhost:11434',
    ollamaModel: '',
  },
});

let mainWindow = null;
let processManager = null;
let healthChecker = null;

/** Check whether we are in dev mode. */
function isDevMode() {
  if (process.env.ELECTRON_DEV === '1') return true;
  const distIndex = path.join(__dirname, '..', 'dist', 'index.html');
  return !fs.existsSync(distIndex);
}

app.whenReady().then(() => {
  const basePath = path.join(__dirname, '..');

  // --- Custom protocol to serve dist/ with correct MIME types ---
  if (!isDevMode()) {
    const distDir = path.join(basePath, 'dist');
    protocol.handle('app', (request) => {
      let urlPath = new URL(request.url).pathname;
      // Strip leading slash; default to index.html
      if (urlPath === '/' || urlPath === '') urlPath = '/index.html';
      const filePath = path.join(distDir, urlPath);
      return net.fetch('file://' + filePath);
    });
  }

  // --- Process Manager ---
  processManager = new ProcessManager(basePath, store);

  // Start backend service (always on)
  processManager.startService('backend');

  // --- Health Checker ---
  healthChecker = new HealthChecker();
  healthChecker.setState('backend', 'starting');
  healthChecker.start();

  // Forward health status changes to renderer
  healthChecker.onStatusChange((status) => {
    if (mainWindow && !mainWindow.isDestroyed()) {
      mainWindow.webContents.send('service-status-changed', status);
    }
  });

  // Forward process manager status changes
  processManager.onStatusChange((status) => {
    if (mainWindow && !mainWindow.isDestroyed()) {
      mainWindow.webContents.send('service-status-changed', healthChecker.getStatus());
    }
  });

  // --- BrowserWindow ---
  mainWindow = new BrowserWindow({
    width: 1400,
    height: 900,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
    },
  });

  if (isDevMode()) {
    log.info('Running in dev mode — loading from http://localhost:9003');
    mainWindow.loadURL('http://localhost:9003');
    mainWindow.webContents.openDevTools();
  } else {
    log.info('Running in production mode — loading app://dist/');
    mainWindow.loadURL('app://dist/');
  }

  mainWindow.on('closed', () => {
    mainWindow = null;
  });

  // --- IPC Handlers ---
  ipcMain.handle('get-service-status', () => {
    return healthChecker.getStatus();
  });

  ipcMain.handle('toggle-service', async (_event, name, enabled) => {
    if (enabled) {
      healthChecker.setState(name, 'starting');
      processManager.startService(name);
    } else {
      await processManager.stopService(name);
      healthChecker.setState(name, 'stopped');
    }
    return healthChecker.getStatus();
  });

  ipcMain.handle('get-platform-info', () => {
    return {
      platform: process.platform,
      memory: os.totalmem(),
    };
  });

  // --- Settings IPC Handlers ---
  const validSettingsKeys = Object.keys(settingsSchema);

  ipcMain.handle('get-settings', () => {
    const settings = {};
    for (const key of validSettingsKeys) {
      settings[key] = store.get(key);
    }
    return settings;
  });

  ipcMain.handle('get-setting', (_event, key) => {
    if (!validSettingsKeys.includes(key)) {
      throw new Error(`Unknown setting key: ${key}`);
    }
    return store.get(key);
  });

  ipcMain.handle('set-setting', async (_event, { key, value }) => {
    if (!validSettingsKeys.includes(key)) {
      throw new Error(`Unknown setting key: ${key}`);
    }
    const oldValue = store.get(key);
    store.set(key, value);
    log.info(`Setting changed: ${key} = ${value}`);

    // Restart chat service when LLM backend changes
    if (key === 'llmBackend' && oldValue !== value) {
      log.info(`LLM backend changed from ${oldValue} to ${value} — restarting chat service`);
      healthChecker.setState('chat', 'starting');
      await processManager.stopService('chat');
      processManager.startService('chat');
    }

    return store.get(key);
  });
});

// --- App lifecycle ---
app.on('before-quit', async () => {
  log.info('App quitting — stopping all services');
  if (healthChecker) healthChecker.stop();
  if (processManager) await processManager.stopAll();
});

app.on('window-all-closed', () => {
  app.quit();
});
