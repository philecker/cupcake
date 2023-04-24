// main.js
// Modules to control application life and create native browser window
const { app, BrowserWindow, Menu, Tray } = require('electron');
const path = require('path');

let tray = null;
let browserWindow = null;

const createWindow = () => {
  // Create the browser window.
  browserWindow = new BrowserWindow({
    titleBarStyle: 'hidden',
    minWidth: 270,
    maxWidth: 270,
    maxHeight: 150,
    width: 270,
    show: false,
    frame: false,
    tray: true,
    closable: false,
    minimizable: false,
    maximizable: false,
    fullscreenable: false,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      nodeIntegration: true
    }
  })

  // and load the index.html of the app.
  browserWindow.loadFile('index.html')
  browserWindow.setMenu(null);
  browserWindow.hide();
  browserWindow.removeMenu()
  // Open the DevTools.
  browserWindow.openDevTools({detached: true})
}

// This method will be called when Electron has finished
// initialization and is ready to create browser windows.
// Some APIs can only be used after this event occurs.
app.whenReady().then(() => {
  tray = new Tray('./cupcakeTemplate.png')
  tray.setToolTip('Cupcake')

  if (app.dock) app.dock.hide();
  createWindow()
  // const internalIp = ip.address();

  // browserWindow.webContents.executeJavaScript(`
  //   document.getElementById('ip-address').innerHTML = internalIp;
  // `)

  // const trayBounds = tray.getBounds();
  // const windowBounds = browserWindow.getBounds();
  // console.log(trayBounds);
  // console.log(windowBounds);
  // const x = Math.round(trayBounds.x);
  // const y = Math.round(trayBounds.y);
  // console.log(x);
  // console.log(y);
  // browserWindow.setPosition(0, y, false);

  // position electron window realitive to tray icon
  const positionWindow = () => {
    const windowBounds = browserWindow.getBounds();
    const trayBounds = tray.getBounds();

    // Center window horizontally below the tray icon
    const x = Math.round(trayBounds.x + (trayBounds.width / 2) - (windowBounds.width / 2));

    // Position window 4 pixels vertically below the tray icon
    const y = Math.round(trayBounds.y + trayBounds.height + 4);

    browserWindow.setPosition(x, y, false);
  }



  tray.on('click', () => {
    if (browserWindow.isVisible()) {
      browserWindow.hide();
    } else {
      browserWindow.show();
      positionWindow();
    }
  })

  tray.on('right-click', () => {
    const contextMenu = Menu.buildFromTemplate([
      {
        label: 'Quit', click: () => {
          // electron destroy tray, window and quit app
          tray.destroy();
          browserWindow.destroy();
          app.quit();
        }
      }
    ])

    tray.popUpContextMenu(contextMenu)
  })
})

// Quit when all windows are closed, except on macOS. There, it's common
// for applications and their menu bar to stay active until the user quits
// explicitly with Cmd + Q.
app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit()
})

// In this file you can include the rest of your app's specific main process
// code. You can also put them in separate files and require them here.