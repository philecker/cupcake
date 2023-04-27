// main.js
// Modules to control application life and create native browser window
const { app, BrowserWindow, Menu, Tray } = require('electron');
const path = require('path');

let tray = null;
let browserWindow = null;

const createWindow = () => {
  // Create the browser window.
  browserWindow = new BrowserWindow({
    useContentSize: true,
    titleBarStyle: 'hidden',
    minWidth: 250,
    maxWidth: 250,
    width: 250,
    height: 140,
    minHeight: 140,
    backgroundColor: "#ffffff",
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
  browserWindow.openDevTools({ detached: true })
}

// This method will be called when Electron has finished
// initialization and is ready to create browser windows.
// Some APIs can only be used after this event occurs.
app.whenReady().then(() => {
  tray = new Tray('./cupcakeTemplate.png')
  tray.setToolTip('Cupcake')

  if (app.dock) app.dock.hide();
  createWindow()

  browserWindow.webContents.on('did-finish-load', () => {
    let code = `const copyToClipboard = (text) => {
                  navigator.clipboard.writeText(text).then(() => {
                    /* clipboard successfully set */

                  }, () => {
                    /* clipboard write failed */
                  });
                }

                let listElements = document.getElementById("itemsList");
                listElements.addEventListener("click", (e) => {
                  if (e.target.nodeName == "DIV") {
                    const copiedValue = e.target.querySelector("span").innerHTML;
                    copyToClipboard(copiedValue);
                  } else {
                    const copiedValue = e.target.parentNode.querySelector("span").innerHTML;
                    copyToClipboard(copiedValue);
                  }
                });`;
    browserWindow.webContents.executeJavaScript(code);
  });

  // position electron window realitive to tray icon
  const positionWindow = () => {
    const windowBounds = browserWindow.getBounds();
    const trayBounds = tray.getBounds();

    // Center window horizontally below the tray icon
    const x = Math.round(trayBounds.x + (trayBounds.width / 2) - (windowBounds.width / 2));

    // Position window 4 pixels vertically below the tray icon
    const y = Math.round(trayBounds.y + trayBounds.height);

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
