// main.js
// Modules to control application life and create native browser window
const { app, BrowserWindow, Menu, Tray } = require('electron')
const positioner = require('electron-traywindow-positioner');
const path = require('path')

let tray = null;
let mainWindow = null;

const createWindow = () => {
  // Create the browser window.
  mainWindow = new BrowserWindow({
    titleBarStyle: 'hidden',
    minWidth: 270,
    minHeight: 170,
    maxWidth: 270,
    maxHeight: 170,
    width: 270,
    height: 170,
    show: false,
    frame: false,
    tray: true,
    closable: false,
    minimizable: false,
    maximizable: false,
    fullscreenable: false,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js')
    }
  })

  // and load the index.html of the app.
  mainWindow.loadFile('index.html')
  mainWindow.setMenu(null);
  mainWindow.hide();
  mainWindow.removeMenu()
  // Open the DevTools.
  // mainWindow.webContents.openDevTools()
}

// This method will be called when Electron has finished
// initialization and is ready to create browser windows.
// Some APIs can only be used after this event occurs.
app.whenReady().then(() => {
  if (app.dock) app.dock.hide();

  createWindow()

  tray = new Tray('./cupcakeTemplate.png')
  tray.setToolTip('Cupcake')

  positioner.position(mainWindow, tray.getBounds());

  tray.on('click', () => {

    console.log('👋')
    if (mainWindow.isVisible()) {
      mainWindow.hide()
    } else {
      mainWindow.show()
    }
  })

  tray.on('right-click', () => {
    const menu = Menu.buildFromTemplate([
      {
        label: 'Quit',
        click() { app.quit(); }
      }
    ]);
    tray.popUpContextMenu(menu)
  })
})



const toggleWindow = () => {
  if (mainWindow.isVisible()) return mainWindow.hide();
  // mainWindow.webContents.openDevTools()
  return mainWindow.show();
};

// Quit when all windows are closed, except on macOS. There, it's common
// for applications and their menu bar to stay active until the user quits
// explicitly with Cmd + Q.
app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit()
})

// In this file you can include the rest of your app's specific main process
// code. You can also put them in separate files and require them here.