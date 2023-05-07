import React, { useState, useEffect } from 'react';
import copyIcon from './assets/copy.png'
import store  from 'store'

const [cupcakeInfo, setCupcakeInfo] = useState(null);

useEffect(() => {
  function checkUserData() {
    const systemDetails = store.get('cupcakeInfo');
    setCupcakeInfo(systemDetails);
  }

  window.addEventListener('storage', checkUserData)

  return () => {
    window.removeEventListener('storage', checkUserData)
  }
}, [])

function App() {
  return (
    <ul id="itemsList">
      <li>
        <div className="cupcake-label">
          Internal IP: <img className="copyIcon" src={copyIcon} />
          <span id="ip-address">{ cupcakeInfo.cupcakeIp }</span>
        </div>
      </li>
      <li>
        <div className="cupcake-label">
          Username: <img className="copyIcon" src={copyIcon} />
          <span id="computer-name">{ cupcakeInfo.cupcakeUsername }</span>
        </div>
      </li>
      <li>
        <div className="cupcake-label">
          OS Version: <img className="copyIcon" src={copyIcon} />
          <span id="os-version">{ cupcakeInfo.cupcakeOsVersion }</span>
        </div>
      </li>
      <li>
        <div className="cupcake-label">
          Last Restart: <img className="copyIcon" src={copyIcon} />
          <span id="last-restart">{ cupcakeInfo.cupcakeUptime }</span>
        </div>
      </li>
    </ul>
  )
}

export default App
