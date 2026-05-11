import axios from 'axios';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:5001';

const apiService = {
  getWelcomeMessage: async () => {
    try {
      const response = await axios.get(`${API_BASE_URL}/`);
      return response.data;
    } catch (error) {
      throw error;
    }
  },

  getGreeting: async (name, city) => {
    try {
      const response = await axios.get(`${API_BASE_URL}/greeting`, {
        params: {
          Name: name,
          City: city
        }
      });
      return response.data;
    } catch (error) {
      throw error;
    }
  }
};

export default apiService;

