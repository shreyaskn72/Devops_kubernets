import React from 'react';
import './App.css';
import WelcomeSection from './components/WelcomeSection';
import GreetingForm from './components/GreetingForm';

function App() {
  return (
    <div className="App">
      <div className="container">
        <h1>🚀 Flask API Frontend</h1>
        <p className="subtitle">Built with React & Kubernetes</p>

        <div className="sections">
          <WelcomeSection />
          <GreetingForm />
        </div>
      </div>
    </div>
  );
}

export default App;

