const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('electronAPI', {
  getServiceStatus: () => ipcRenderer.invoke('get-service-status'),
  toggleService: (name, enabled) => ipcRenderer.invoke('toggle-service', name, enabled),
  onServiceStatusChange: (callback) =>
    ipcRenderer.on('service-status-changed', (_event, status) => callback(status)),
  getPlatformInfo: () => ipcRenderer.invoke('get-platform-info'),

  // Settings API
  getSettings: () => ipcRenderer.invoke('get-settings'),
  getSetting: (key) => ipcRenderer.invoke('get-setting', key),
  setSetting: (key, value) => ipcRenderer.invoke('set-setting', { key, value }),
});
