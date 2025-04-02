import React, { useState } from 'react';
import axios from 'axios';
import './App.css';

function App() {
  const [inputText, setInputText] = useState('');
  const [imageUrl, setImageUrl] = useState('');
  const [loading, setLoading] = useState(false);
  const [metrics, setMetrics] = useState(null);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    
    try {
      // Use environment variable for API URL or fallback to relative path
      const apiUrl = process.env.REACT_APP_API_URL || '';
      console.log('Using API URL:', apiUrl); // Log the API URL being used
      const response = await axios.post(`${apiUrl}/generate`, { text: inputText });
      setImageUrl(response.data.imageUrl);
      setMetrics(response.data.metrics);
    } catch (error) {
      console.error('Error generating image:', error);
      alert('Failed to generate image. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="App">
      <header className="App-header">
        <h1>Letter-by-Letter Image Generator</h1>
        <p>EKS AutoMode Demo Application</p>
      </header>
      
      <main>
        <form onSubmit={handleSubmit}>
          <div className="input-group">
            <input
              type="text"
              value={inputText}
              onChange={(e) => setInputText(e.target.value)}
              placeholder="Enter text to generate an image"
              required
            />
            <button type="submit" disabled={loading}>
              {loading ? 'Generating...' : 'Generate Image'}
            </button>
          </div>
        </form>

        {loading && (
          <div className="loading-container">
            <div className="loading-spinner"></div>
            <p>Generating your image...</p>
          </div>
        )}

        {imageUrl && !loading && (
          <div className="result-container">
            <h2>Generated Image</h2>
            <div className="image-container">
              <img src={imageUrl} alt="Generated text" />
            </div>
          </div>
        )}

        {metrics && (
          <div className="metrics-container">
            <h2>Request Metrics</h2>
            <div className="metrics-grid">
              <div className="metric-card">
                <h3>Total Time</h3>
                <p>{metrics.totalTime}ms</p>
              </div>
              <div className="metric-card">
                <h3>Services Used</h3>
                <p>{metrics.servicesUsed}</p>
              </div>
              <div className="metric-card">
                <h3>Characters Processed</h3>
                <p>{metrics.charactersProcessed}</p>
              </div>
            </div>
            
            <h3>Service Breakdown</h3>
            <div className="service-metrics">
              {metrics.serviceBreakdown && metrics.serviceBreakdown.map((service, index) => (
                <div key={index} className="service-metric">
                  <span className="service-name">{service.name}:</span>
                  <span className="service-time">{service.time}ms</span>
                </div>
              ))}
            </div>
          </div>
        )}
      </main>
      
      <footer>
        <p>EKS AutoMode Demo - Letter-by-Letter Image Generator</p>
      </footer>
    </div>
  );
}

export default App;
