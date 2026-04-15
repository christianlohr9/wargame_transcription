const { app, BrowserWindow, ipcMain } = require('electron');
const path = require('path');
const fs = require('fs');
const os = require('os');
const log = require('electron-log');
const { ProcessManager } = require('./processManager');
const { HealthChecker } = require('./healthChecker');

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

  // --- Process Manager ---
  processManager = new ProcessManager(basePath);

  // Start backend service (always on)
  processManager.startService('backend');

  // --- Health Checker ---
  healthChecker = new HealthChecker();
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
    const distIndex = path.join(__dirname, '..', 'dist', 'index.html');
    log.info(`Running in production mode — loading ${distIndex}`);
    mainWindow.loadFile(distIndex);
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
      processManager.startService(name);
    } else {
      await processManager.stopService(name);
    }
    return healthChecker.getStatus();
  });

  ipcMain.handle('get-platform-info', () => {
    return {
      platform: process.platform,
      memory: os.totalmem(),
    };
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
