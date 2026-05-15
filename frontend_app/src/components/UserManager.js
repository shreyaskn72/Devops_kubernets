import React, { useState, useEffect } from 'react';
import '../styles/UserManager.css';
import apiService from '../services/apiService';

function UserManager() {
  const [activeTab, setActiveTab] = useState('list');
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);

  // Form states
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    city: '',
    age: ''
  });
  const [editingId, setEditingId] = useState(null);
  const [searchUserId, setSearchUserId] = useState('');
  const [searchedUser, setSearchedUser] = useState(null);

  // Load users on component mount and when page changes
  useEffect(() => {
    if (activeTab === 'list') {
      fetchUsers(currentPage);
    }
  }, [activeTab, currentPage]);

  const fetchUsers = async (page = 1) => {
    setLoading(true);
    setError('');
    try {
      const response = await apiService.getAllUsers(page, 10);
      setUsers(response.users);
      setTotalPages(response.pages);
      setCurrentPage(response.current_page);
    } catch (err) {
      setError(err.response?.data?.error || 'Failed to fetch users');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const resetForm = () => {
    setFormData({ name: '', email: '', city: '', age: '' });
    setEditingId(null);
    setError('');
  };

  const handleCreateUser = async (e) => {
    e.preventDefault();
    setError('');
    setSuccess('');

    if (!formData.name || !formData.email || !formData.city) {
      setError('Name, email, and city are required');
      return;
    }

    setLoading(true);
    try {
      const userData = {
        name: formData.name,
        email: formData.email,
        city: formData.city,
        age: formData.age ? parseInt(formData.age) : null
      };

      await apiService.createUser(userData);
      setSuccess('User created successfully!');
      resetForm();
      if (activeTab === 'list') {
        fetchUsers(1);
      }
      setActiveTab('list');
    } catch (err) {
      setError(err.response?.data?.error || 'Failed to create user');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const handleUpdateUser = async (e) => {
    e.preventDefault();
    if (!editingId) return;

    setError('');
    setSuccess('');

    setLoading(true);
    try {
      const updateData = {};
      if (formData.name) updateData.name = formData.name;
      if (formData.email) updateData.email = formData.email;
      if (formData.city) updateData.city = formData.city;
      if (formData.age) updateData.age = parseInt(formData.age);

      await apiService.updateUser(editingId, updateData);
      setSuccess('User updated successfully!');
      resetForm();
      if (activeTab === 'list') {
        fetchUsers(currentPage);
      }
      setActiveTab('list');
    } catch (err) {
      setError(err.response?.data?.error || 'Failed to update user');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteUser = async (userId) => {
    if (window.confirm('Are you sure you want to delete this user?')) {
      setLoading(true);
      setError('');
      setSuccess('');
      try {
        await apiService.deleteUser(userId);
        setSuccess('User deleted successfully!');
        fetchUsers(currentPage);
      } catch (err) {
        setError(err.response?.data?.error || 'Failed to delete user');
        console.error(err);
      } finally {
        setLoading(false);
      }
    }
  };

  const handleEditUser = (user) => {
    setFormData({
      name: user.name,
      email: user.email,
      city: user.city,
      age: user.age || ''
    });
    setEditingId(user.id);
    setActiveTab('create');
  };

  const handleSearchUser = async (e) => {
    e.preventDefault();
    if (!searchUserId.trim()) {
      setError('Please enter a user ID');
      return;
    }

    setLoading(true);
    setError('');
    setSearchedUser(null);
    try {
      const user = await apiService.getUserById(searchUserId);
      setSearchedUser(user);
    } catch (err) {
      setError(err.response?.data?.error || 'User not found');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="user-manager">
      <h2>👥 User Management (CRUD Operations)</h2>

      {/* Tabs */}
      <div className="tabs">
        <button
          className={`tab-btn ${activeTab === 'list' ? 'active' : ''}`}
          onClick={() => { setActiveTab('list'); setError(''); setSuccess(''); }}
        >
          📋 View All Users
        </button>
        <button
          className={`tab-btn ${activeTab === 'create' ? 'active' : ''}`}
          onClick={() => {
            setActiveTab('create');
            resetForm();
            setError('');
            setSuccess('');
          }}
        >
          ➕ {editingId ? 'Edit User' : 'Create User'}
        </button>
        <button
          className={`tab-btn ${activeTab === 'search' ? 'active' : ''}`}
          onClick={() => { setActiveTab('search'); setError(''); setSuccess(''); }}
        >
          🔍 Search User
        </button>
      </div>

      {/* Alert Messages */}
      {error && <div className="alert alert-error">{error}</div>}
      {success && <div className="alert alert-success">{success}</div>}

      {/* Tab Content */}

      {/* View All Users Tab */}
      {activeTab === 'list' && (
        <div className="tab-content">
          {loading ? (
            <p className="loading">Loading users...</p>
          ) : users.length > 0 ? (
            <>
              <div className="users-table-wrapper">
                <table className="users-table">
                  <thead>
                    <tr>
                      <th>ID</th>
                      <th>Name</th>
                      <th>Email</th>
                      <th>City</th>
                      <th>Age</th>
                      <th>Created At</th>
                      <th>Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {users.map(user => (
                      <tr key={user.id}>
                        <td>{user.id}</td>
                        <td>{user.name}</td>
                        <td>{user.email}</td>
                        <td>{user.city}</td>
                        <td>{user.age || 'N/A'}</td>
                        <td>{new Date(user.created_at).toLocaleDateString()}</td>
                        <td className="actions">
                          <button
                            className="btn-edit"
                            onClick={() => handleEditUser(user)}
                          >
                            ✏️ Edit
                          </button>
                          <button
                            className="btn-delete"
                            onClick={() => handleDeleteUser(user.id)}
                          >
                            🗑️ Delete
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>

              {/* Pagination */}
              <div className="pagination">
                <button
                  onClick={() => setCurrentPage(Math.max(1, currentPage - 1))}
                  disabled={currentPage === 1 || loading}
                >
                  ← Previous
                </button>
                <span className="page-info">
                  Page {currentPage} of {totalPages}
                </span>
                <button
                  onClick={() => setCurrentPage(Math.min(totalPages, currentPage + 1))}
                  disabled={currentPage === totalPages || loading}
                >
                  Next →
                </button>
              </div>
            </>
          ) : (
            <p className="no-data">No users found. Create one to get started!</p>
          )}
        </div>
      )}

      {/* Create/Edit User Tab */}
      {activeTab === 'create' && (
        <div className="tab-content">
          <form onSubmit={editingId ? handleUpdateUser : handleCreateUser} className="user-form">
            <div className="form-group">
              <label htmlFor="name">Name *</label>
              <input
                type="text"
                id="name"
                name="name"
                value={formData.name}
                onChange={handleInputChange}
                placeholder="Enter user name"
                className="input-field"
              />
            </div>

            <div className="form-group">
              <label htmlFor="email">Email *</label>
              <input
                type="email"
                id="email"
                name="email"
                value={formData.email}
                onChange={handleInputChange}
                placeholder="Enter user email"
                className="input-field"
              />
            </div>

            <div className="form-group">
              <label htmlFor="city">City *</label>
              <input
                type="text"
                id="city"
                name="city"
                value={formData.city}
                onChange={handleInputChange}
                placeholder="Enter user city"
                className="input-field"
              />
            </div>

            <div className="form-group">
              <label htmlFor="age">Age (Optional)</label>
              <input
                type="number"
                id="age"
                name="age"
                value={formData.age}
                onChange={handleInputChange}
                placeholder="Enter user age"
                className="input-field"
                min="0"
                max="150"
              />
            </div>

            <div className="form-actions">
              <button type="submit" className="btn btn-primary" disabled={loading}>
                {loading ? 'Processing...' : (editingId ? 'Update User' : 'Create User')}
              </button>
              {editingId && (
                <button
                  type="button"
                  className="btn btn-secondary"
                  onClick={() => {
                    resetForm();
                    setActiveTab('list');
                  }}
                >
                  Cancel
                </button>
              )}
            </div>
          </form>
        </div>
      )}

      {/* Search User Tab */}
      {activeTab === 'search' && (
        <div className="tab-content">
          <form onSubmit={handleSearchUser} className="search-form">
            <div className="form-group">
              <label htmlFor="userId">User ID:</label>
              <input
                type="number"
                id="userId"
                value={searchUserId}
                onChange={(e) => setSearchUserId(e.target.value)}
                placeholder="Enter user ID to search"
                className="input-field"
              />
            </div>
            <button type="submit" className="btn btn-primary" disabled={loading}>
              {loading ? 'Searching...' : 'Search'}
            </button>
          </form>

          {searchedUser && (
            <div className="user-details">
              <h3>User Details</h3>
              <div className="details-grid">
                <div className="detail-item">
                  <span className="detail-label">ID:</span>
                  <span className="detail-value">{searchedUser.id}</span>
                </div>
                <div className="detail-item">
                  <span className="detail-label">Name:</span>
                  <span className="detail-value">{searchedUser.name}</span>
                </div>
                <div className="detail-item">
                  <span className="detail-label">Email:</span>
                  <span className="detail-value">{searchedUser.email}</span>
                </div>
                <div className="detail-item">
                  <span className="detail-label">City:</span>
                  <span className="detail-value">{searchedUser.city}</span>
                </div>
                <div className="detail-item">
                  <span className="detail-label">Age:</span>
                  <span className="detail-value">{searchedUser.age || 'N/A'}</span>
                </div>
                <div className="detail-item">
                  <span className="detail-label">Created At:</span>
                  <span className="detail-value">{new Date(searchedUser.created_at).toLocaleString()}</span>
                </div>
              </div>
              <div className="user-actions">
                <button
                  className="btn btn-edit"
                  onClick={() => handleEditUser(searchedUser)}
                >
                  ✏️ Edit This User
                </button>
                <button
                  className="btn btn-delete"
                  onClick={() => handleDeleteUser(searchedUser.id)}
                >
                  🗑️ Delete This User
                </button>
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}

export default UserManager;

