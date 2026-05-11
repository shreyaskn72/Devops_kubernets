import React, { useState, useEffect } from 'react';
import '../styles/WelcomeSection.css';
import apiService from '../services/apiService';

function WelcomeSection() {
  const [message, setMessage] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    fetchWelcomeMessage();
  }, []);

  const fetchWelcomeMessage = async () => {
    setLoading(true);
    setError('');
    try {
      const response = await apiService.getWelcomeMessage();
      setMessage(response.message);
    } catch (err) {
      setError('Failed to fetch welcome message');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="welcome-section">
      <h2>👋 Welcome</h2>

      {loading && <p className="loading">Loading...</p>}
      {error && <p className="error">{error}</p>}
      {message && (
        <div className="message-box">
          <p>{message}</p>
        </div>
      )}

      <button onClick={fetchWelcomeMessage} className="btn">
        Refresh Message
      </button>
    </div>
  );
}

export default WelcomeSection;

