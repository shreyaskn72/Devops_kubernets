import axios from 'axios';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:5001';

const apiService = {
  // Home endpoint
  getWelcomeMessage: async () => {
    try {
      const response = await axios.get(`${API_BASE_URL}/`);
      return response.data;
    } catch (error) {
      throw error;
    }
  },

  // Greeting endpoint
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
  },

  // CRUD Operations - Users

  // CREATE - Add new user
  createUser: async (userData) => {
    try {
      const response = await axios.post(`${API_BASE_URL}/api/users`, userData);
      return response.data;
    } catch (error) {
      throw error;
    }
  },

  // READ - Get all users
  getAllUsers: async (page = 1, perPage = 10) => {
    try {
      const response = await axios.get(`${API_BASE_URL}/api/users`, {
        params: {
          page,
          per_page: perPage
        }
      });
      return response.data;
    } catch (error) {
      throw error;
    }
  },

  // READ - Get single user by ID
  getUserById: async (userId) => {
    try {
      const response = await axios.get(`${API_BASE_URL}/api/users/${userId}`);
      return response.data;
    } catch (error) {
      throw error;
    }
  },

  // UPDATE - Modify user
  updateUser: async (userId, userData) => {
    try {
      const response = await axios.put(`${API_BASE_URL}/api/users/${userId}`, userData);
      return response.data;
    } catch (error) {
      throw error;
    }
  },

  // DELETE - Remove user
  deleteUser: async (userId) => {
    try {
      const response = await axios.delete(`${API_BASE_URL}/api/users/${userId}`);
      return response.data;
    } catch (error) {
      throw error;
    }
  },

  // BULK UPLOAD - Upload users from CSV file
  bulkUploadUsers: async (file) => {
    try {
      const formData = new FormData();
      formData.append('file', file);
      const response = await axios.post(`${API_BASE_URL}/api/users/bulk-upload`, formData, {
        headers: {
          'Content-Type': 'multipart/form-data'
        }
      });
      return response.data;
    } catch (error) {
      if (error.response && error.response.data && error.response.data.error) {
        throw new Error(error.response.data.error);
      }
      throw error;
    }
  },

  // Health check
  checkHealth: async () => {
    try {
      const response = await axios.get(`${API_BASE_URL}/health`);
      return response.data;
    } catch (error) {
      throw error;
    }
  }
};

export { apiService as default };
export const { bulkUploadUsers } = apiService;

