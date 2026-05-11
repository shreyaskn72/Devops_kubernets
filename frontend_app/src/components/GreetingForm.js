import React, { useState } from 'react';
import '../styles/GreetingForm.css';
import apiService from '../services/apiService';

function GreetingForm() {
  const [formData, setFormData] = useState({
    Name: '',
    City: ''
  });
  const [greeting, setGreeting] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();

    if (!formData.Name || !formData.City) {
      setError('Please fill in all fields');
      return;
    }

    setLoading(true);
    setError('');

    try {
      const response = await apiService.getGreeting(formData.Name, formData.City);
      setGreeting(response);
    } catch (err) {
      setError(err.response?.data?.Message || 'Failed to fetch greeting');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="greeting-section">
      <h2>💬 Personalized Greeting</h2>

      <form onSubmit={handleSubmit} className="form">
        <div className="form-group">
          <label htmlFor="Name">Name:</label>
          <input
            type="text"
            id="Name"
            name="Name"
            value={formData.Name}
            onChange={handleChange}
            placeholder="Enter your name"
            className="input-field"
          />
        </div>

        <div className="form-group">
          <label htmlFor="City">City:</label>
          <input
            type="text"
            id="City"
            name="City"
            value={formData.City}
            onChange={handleChange}
            placeholder="Enter your city"
            className="input-field"
          />
        </div>

        <button type="submit" className="btn" disabled={loading}>
          {loading ? 'Loading...' : 'Get Greeting'}
        </button>
      </form>

      {error && <p className="error">{error}</p>}

      {greeting && (
        <div className="greeting-box">
          <p className="greeting-title">{greeting.Greeting}</p>
          <p className="greeting-message">{greeting.Message}</p>
        </div>
      )}
    </div>
  );
}

export default GreetingForm;

