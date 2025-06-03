const { app, BrowserWindow } = require("electron");
const path = require("path");
const url = require("url");

const isDev = !app.isPackaged;

let mainWindow;

app.on("ready", () => {
  console.log("Launching Electron window...");

  mainWindow = new BrowserWindow({
    width: 800,
    height: 600,
    webPreferences: {
      nodeIntegration: true,
    },
  });

  const indexPath = isDev
    ? "http://localhost:5173"
    : url.format({
      pathname: path.join(__dirname, "dist", "index.html"),
      protocol: "file:",
      slashes: true,
    });

  mainWindow.loadURL(indexPath);

  mainWindow.on("closed", () => {
    mainWindow = null;
  });
});

app.on("window-all-closed", () => {
  if (process.platform !== "darwin") {
    app.quit();
  }
});
