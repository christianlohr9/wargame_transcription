const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('electronAPI', {
  getServiceStatus: () => ipcRenderer.invoke('get-service-status'),
  toggleService: (name, enabled) => ipcRenderer.invoke('toggle-service', name, enabled),
  onServiceStatusChange: (callback) =>
    ipcRenderer.on('service-status-changed', (_event, status) => callback(status)),
  getPlatformInfo: () => ipcRenderer.invoke('get-platform-info'),
});
