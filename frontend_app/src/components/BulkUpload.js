import React, { useState, useEffect } from 'react';
import '../styles/BulkUpload.css';
import { bulkUploadUsers, getBulkUploadStatus } from '../services/apiService';

function BulkUpload() {
  const [file, setFile] = useState(null);
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState('');
  const [uploadResult, setUploadResult] = useState(null);
  const [showSample, setShowSample] = useState(false);
  const [uploadHistory, setUploadHistory] = useState([]);
  const [statusLoading, setStatusLoading] = useState({});
  const [expandedTask, setExpandedTask] = useState(null);

  const handleFileChange = (e) => {
    const selectedFile = e.target.files[0];
    if (selectedFile) {
      if (selectedFile.type !== 'text/csv' && !selectedFile.name.endsWith('.csv')) {
        setMessage('❌ Please select a valid CSV file');
        setFile(null);
        return;
      }
      setFile(selectedFile);
      setMessage('✅ CSV file selected');
    }
  };

  const handleUpload = async (e) => {
    e.preventDefault();

    if (!file) {
      setMessage('❌ Please select a CSV file');
      return;
    }

    setLoading(true);
    setMessage('⏳ Uploading...');

    try {
      const result = await bulkUploadUsers(file);
      setUploadResult(result);
      setMessage(`✅ ${result.message}`);

      // Add to upload history
      const newTask = {
        task_id: result.task_id,
        filename: file.name,
        timestamp: new Date().toLocaleString(),
        status: result.status,
        result: null
      };
      setUploadHistory([newTask, ...uploadHistory]);

      setFile(null);
      document.getElementById('fileInput').value = '';
    } catch (error) {
      setMessage(`❌ Error: ${error.message}`);
      setUploadResult(null);
    } finally {
      setLoading(false);
    }
  };

  const checkTaskStatus = async (taskId, index) => {
    setStatusLoading({ ...statusLoading, [taskId]: true });
    try {
      const statusResult = await getBulkUploadStatus(taskId);

      // Update upload history with new status
      const updatedHistory = [...uploadHistory];
      updatedHistory[index] = {
        ...updatedHistory[index],
        status: statusResult.state,
        result: statusResult
      };
      setUploadHistory(updatedHistory);

      setExpandedTask(taskId);
    } catch (error) {
      alert(`❌ Error checking status: ${error.message}`);
    } finally {
      setStatusLoading({ ...statusLoading, [taskId]: false });
    }
  };

  const getStatusColor = (state) => {
    switch (state) {
      case 'SUCCESS':
        return '#27ae60';
      case 'FAILURE':
        return '#e74c3c';
      case 'PROCESSING':
        return '#f39c12';
      case 'PENDING':
        return '#3498db';
      default:
        return '#95a5a6';
    }
  };

  const getStatusIcon = (state) => {
    switch (state) {
      case 'SUCCESS':
        return '✅';
      case 'FAILURE':
        return '❌';
      case 'PROCESSING':
        return '⏳';
      case 'PENDING':
        return '⏱️';
      default:
        return '❓';
    }
  };

  const downloadSampleCSV = () => {
    const sampleData = `name,city,email,age
John Doe,New York,john.doe@example.com,28
Jane Smith,Los Angeles,jane.smith@example.com,32
Mike Johnson,Chicago,mike.johnson@example.com,45
Sarah Williams,Houston,sarah.williams@example.com,29
Tom Brown,Phoenix,tom.brown@example.com,35`;

    const blob = new Blob([sampleData], { type: 'text/csv' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'sample_users.csv';
    document.body.appendChild(a);
    a.click();
    window.URL.revokeObjectURL(url);
    document.body.removeChild(a);
  };

  return (
    <div className="bulk-upload-container">
      <h2>📤 Bulk Upload Users (CSV)</h2>
      <p className="info-text">Upload up to 10 users at once from a CSV file</p>

      {/* Sample CSV Section */}
      <div className="sample-section">
        <button
          className="sample-btn"
          onClick={() => setShowSample(!showSample)}
        >
          {showSample ? '▼' : '▶'} CSV Format Requirements
        </button>

        {showSample && (
          <div className="sample-content">
            <h4>Required Columns:</h4>
            <ul>
              <li><strong>name</strong> (required) - User's full name</li>
              <li><strong>city</strong> (required) - User's city</li>
              <li><strong>email</strong> (required) - User's email address (must be unique)</li>
              <li><strong>age</strong> (optional) - User's age (0-150)</li>
            </ul>

            <h4>Example CSV Format:</h4>
            <pre className="sample-csv">
{`name,city,email,age
John Doe,New York,john@example.com,28
Jane Smith,Los Angeles,jane@example.com,32
Mike Johnson,Chicago,mike@example.com,45`}
            </pre>

            <button className="download-btn" onClick={downloadSampleCSV}>
              ⬇️ Download Sample CSV
            </button>
          </div>
        )}
      </div>

      {/* Upload Form */}
      <form onSubmit={handleUpload} className="upload-form">
        <div className="file-input-wrapper">
          <label htmlFor="fileInput" className="file-label">
            📁 Select CSV File
          </label>
          <input
            id="fileInput"
            type="file"
            accept=".csv"
            onChange={handleFileChange}
            disabled={loading}
            className="file-input"
          />
          {file && (
            <span className="file-name">
              ✓ {file.name} ({(file.size / 1024).toFixed(2)} KB)
            </span>
          )}
        </div>

        <div className="constraints">
          <p>⚠️ <strong>Constraints:</strong></p>
          <ul>
            <li>Maximum 10 users per file</li>
            <li>Maximum file size: 5MB</li>
            <li>Email must be unique across database</li>
            <li>All required fields must be filled</li>
          </ul>
        </div>

        <button
          type="submit"
          disabled={loading || !file}
          className="upload-submit-btn"
        >
          {loading ? '⏳ Uploading...' : '🚀 Upload Users'}
        </button>
      </form>

      {/* Status Message */}
      {message && (
        <div className={`message ${message.includes('✅') ? 'success' : message.includes('❌') ? 'error' : 'info'}`}>
          {message}
        </div>
      )}

      {/* Upload Result */}
      {uploadResult && (
        <div className="upload-result">
          <h3>📊 Upload Summary</h3>

          {uploadResult.uploaded_count > 0 && (
            <div className="success-section">
              <h4>✅ Successfully Uploaded ({uploadResult.uploaded_count})</h4>
              <div className="users-list">
                {uploadResult.uploaded_users.map((user, index) => (
                  <div key={index} className="user-card">
                    <div className="user-info">
                      <p><strong>{user.name}</strong></p>
                      <p className="email">{user.email}</p>
                      <p className="details">{user.city} {user.age ? `• Age: ${user.age}` : ''}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {uploadResult.failed_count > 0 && (
            <div className="error-section">
              <h4>❌ Failed Records ({uploadResult.failed_count})</h4>
              <div className="failures-list">
                {uploadResult.failed_records.map((record, index) => (
                  <div key={index} className="failure-item">
                    <span className="row-number">Row {record.row}:</span>
                    <span className="error-msg">{record.error}</span>
                  </div>
                ))}
              </div>
            </div>
          )}

          <div className="result-summary">
            <p>📈 Total Processed: {uploadResult.uploaded_count + uploadResult.failed_count}</p>
            <p>✓ Success Rate: {((uploadResult.uploaded_count / (uploadResult.uploaded_count + uploadResult.failed_count)) * 100).toFixed(1)}%</p>
          </div>
        </div>
      )}

      {/* Upload History & Status Tracking */}
      {uploadHistory.length > 0 && (
        <div className="upload-history-container">
          <h3>📋 Upload History & Status Tracker</h3>
          <div className="upload-history-list">
            {uploadHistory.map((task, index) => (
              <div key={task.task_id} className="history-item">
                <div className="history-header">
                  <div className="history-info">
                    <span className="status-badge" style={{ backgroundColor: getStatusColor(task.status) }}>
                      {getStatusIcon(task.status)} {task.status}
                    </span>
                    <span className="task-id">ID: {task.task_id.substring(0, 8)}...</span>
                    <span className="filename">📄 {task.filename}</span>
                    <span className="timestamp">⏰ {task.timestamp}</span>
                  </div>
                  <div className="history-actions">
                    <button
                      className="status-check-btn"
                      onClick={() => checkTaskStatus(task.task_id, index)}
                      disabled={statusLoading[task.task_id]}
                    >
                      {statusLoading[task.task_id] ? '🔄 Checking...' : '🔍 Check Status'}
                    </button>
                    <button
                      className="expand-btn"
                      onClick={() => setExpandedTask(expandedTask === task.task_id ? null : task.task_id)}
                    >
                      {expandedTask === task.task_id ? '▲' : '▼'}
                    </button>
                  </div>
                </div>

                {/* Expanded Status Details */}
                {expandedTask === task.task_id && task.result && (
                  <div className="history-details">
                    <div className="status-details">
                      <p><strong>State:</strong> {task.result.state}</p>
                      {task.result.state === 'PROCESSING' && (
                        <div className="progress-info">
                          <p><strong>Progress:</strong> {task.result.current} / {task.result.total}</p>
                          <div className="progress-bar">
                            <div
                              className="progress-fill"
                              style={{ width: `${(task.result.current / task.result.total) * 100}%` }}
                            ></div>
                          </div>
                        </div>
                      )}
                      {task.result.state === 'SUCCESS' && (
                        <div className="success-details">
                          <p>✅ <strong>Message:</strong> {task.result.result.message}</p>
                          <p>📤 <strong>Uploaded:</strong> {task.result.result.uploaded_count}</p>
                          <p>❌ <strong>Failed:</strong> {task.result.result.failed_count}</p>
                          {task.result.result.failed_count > 0 && (
                            <div className="failed-details">
                              <p><strong>Failed Records:</strong></p>
                              {task.result.result.failed_records.map((record, idx) => (
                                <div key={idx} className="failed-record">
                                  Row {record.row}: {record.error}
                                </div>
                              ))}
                            </div>
                          )}
                        </div>
                      )}
                      {task.result.state === 'FAILURE' && (
                        <div className="failure-details">
                          <p>❌ <strong>Error:</strong> {task.result.error}</p>
                        </div>
                      )}
                      {task.result.state === 'PENDING' && (
                        <div className="pending-details">
                          <p>⏱️ {task.result.message}</p>
                        </div>
                      )}
                    </div>
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

export default BulkUpload;

