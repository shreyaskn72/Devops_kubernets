import React, { useState } from 'react';
import './App.css';
import WelcomeSection from './components/WelcomeSection';
import GreetingForm from './components/GreetingForm';
import UserManager from './components/UserManager';
import BulkUpload from './components/BulkUpload';

function App() {
  const [activeSection, setActiveSection] = useState('home');

  return (
    <div className="App">
      <div className="container">
        <h1>🚀 Flask API Frontend</h1>
        <p className="subtitle">Built with React & Kubernetes</p>

        {/* Navigation Tabs */}
        <div className="nav-tabs">
          <button
            className={`nav-btn ${activeSection === 'home' ? 'active' : ''}`}
            onClick={() => setActiveSection('home')}
          >
            🏠 Home
          </button>
          <button
            className={`nav-btn ${activeSection === 'greeting' ? 'active' : ''}`}
            onClick={() => setActiveSection('greeting')}
          >
            💬 Greeting
          </button>
          <button
            className={`nav-btn ${activeSection === 'crud' ? 'active' : ''}`}
            onClick={() => setActiveSection('crud')}
          >
            👥 User CRUD
          </button>
          <button
            className={`nav-btn ${activeSection === 'bulk' ? 'active' : ''}`}
            onClick={() => setActiveSection('bulk')}
          >
            📤 Bulk Upload
          </button>
        </div>

        {/* Content Sections */}
        <div className="sections">
          {activeSection === 'home' && <WelcomeSection />}
          {activeSection === 'greeting' && <GreetingForm />}
          {activeSection === 'crud' && <UserManager />}
          {activeSection === 'bulk' && <BulkUpload />}
        </div>
      </div>
    </div>
  );
}

export default App;

