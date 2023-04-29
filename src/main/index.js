import { app, BrowserWindow, Menu, Tray, nativeImage } from 'electron'
import { join } from 'path'
import trayIcon from '../../resources/cupcakeTemplate.png?asset'

let tray = null
let browserWindow = null

const createWindow = () => {
  browserWindow = new BrowserWindow({
    useContentSize: true,
    titleBarStyle: 'hidden',
    minWidth: 250,
    maxWidth: 250,
    width: 250,
    height: 140,
    minHeight: 140,
    backgroundColor: '#ffffff',
    show: false,
    frame: false,
    tray: true,
    closable: false,
    minimizable: false,
    maximizable: false,
    fullscreenable: false,
    webPreferences: {
      preload: join(__dirname, 'preload.js'),
      nodeIntegration: true
    }
  })

  browserWindow.loadFile('./src/renderer/index.html')
  browserWindow.setMenu(null)
  browserWindow.hide()
  browserWindow.removeMenu()
  browserWindow.openDevTools({ detached: true })
}

app.whenReady().then(() => {
  tray = new Tray(nativeImage.createFromPath(trayIcon))
  tray.setToolTip('Cupcake')

  if (app.dock) app.dock.hide()
  createWindow()

  // browserWindow.webContents.on('did-finish-load', () => {
  //   let code = `const copyToClipboard = (text) => {
  //                 navigator.clipboard.writeText(text).then(() => {

  //                 }, () => {

  //                 });
  //               }

  //               let listElements = document.getElementById("itemsList");
  //               listElements.addEventListener("click", (e) => {
  //                 if (e.target.nodeName == "DIV") {
  //                   const copiedValue = e.target.querySelector("span").innerHTML;
  //                   copyToClipboard(copiedValue);
  //                 } else {
  //                   const copiedValue = e.target.parentNode.querySelector("span").innerHTML;
  //                   copyToClipboard(copiedValue);
  //                 }
  //               });`
  //   browserWindow.webContents.executeJavaScript(code)
  // })

  // position electron window realitive to tray icon
  const positionWindow = () => {
    const windowBounds = browserWindow.getBounds()
    const trayBounds = tray.getBounds()
    const x = Math.round(trayBounds.x + trayBounds.width / 2 - windowBounds.width / 2)
    const y = Math.round(trayBounds.y + trayBounds.height)

    browserWindow.setPosition(x, y, false)
  }

  tray.on('click', () => {
    if (browserWindow.isVisible()) {
      browserWindow.hide()
    } else {
      browserWindow.show()
      positionWindow()
    }
  })

  tray.on('right-click', () => {
    const contextMenu = Menu.buildFromTemplate([
      {
        label: 'Quit',
        click: () => {
          // electron destroy tray, window and quit app
          tray.destroy()
          browserWindow.destroy()
          app.quit()
        }
      }
    ])

    tray.popUpContextMenu(contextMenu)
  })
})

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit()
})
