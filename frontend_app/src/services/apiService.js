import axios from 'axios';

const getApiBaseUrl = () => {
  if (typeof window !== 'undefined' && window.__RUNTIME_CONFIG__?.API_URL) {
    return window.__RUNTIME_CONFIG__.API_URL;
  }

  if (process.env.REACT_APP_API_URL) {
    return process.env.REACT_APP_API_URL;
  }

  if (typeof window === 'undefined') {
    return 'http://localhost:5000';
  }

  const { hostname, protocol } = window.location;
  if (hostname === 'localhost' || hostname === '127.0.0.1') {
    return `${protocol}//${hostname}:5000`;
  }

  const apiHostname = hostname.replace(/-3000(?=\.|$)/, '-5000');

  return `${protocol}//${apiHostname}`;
};

const API_BASE_URL = getApiBaseUrl();

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

   // GET BULK UPLOAD STATUS - Check status of a bulk upload task
   getBulkUploadStatus: async (taskId) => {
     try {
       const response = await axios.get(`${API_BASE_URL}/api/users/bulk-upload/status/${taskId}`);
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
export const { bulkUploadUsers, getBulkUploadStatus } = apiService;

