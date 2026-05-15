import React, { useState } from 'react';
import '../styles/BulkUpload.css';
import { bulkUploadUsers } from '../services/apiService';

function BulkUpload() {
  const [file, setFile] = useState(null);
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState('');
  const [uploadResult, setUploadResult] = useState(null);
  const [showSample, setShowSample] = useState(false);

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
      setFile(null);
      document.getElementById('fileInput').value = '';
    } catch (error) {
      setMessage(`❌ Error: ${error.message}`);
      setUploadResult(null);
    } finally {
      setLoading(false);
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
    </div>
  );
}

export default BulkUpload;

