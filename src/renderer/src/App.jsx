import copyIcon from './assets/copy.png'

function App() {
  return (
    <ul id="itemsList">
      <li>
        <div className="cupcake-label">
          Internal IP: <img className="copyIcon" src={copyIcon} />
          <span id="ip-address"></span>
        </div>
      </li>
      <li>
        <div className="cupcake-label">
          Username: <img className="copyIcon" src={copyIcon} />
          <span id="computer-name"></span>
        </div>
      </li>
      <li>
        <div className="cupcake-label">
          OS Version: <img className="copyIcon" src={copyIcon} />
          <span id="os-version"></span>
        </div>
      </li>
      <li>
        <div className="cupcake-label">
          Last Restart: <img className="copyIcon" src={copyIcon} />
          <span id="last-restart"></span>
        </div>
      </li>
    </ul>
  )
}

export default App
