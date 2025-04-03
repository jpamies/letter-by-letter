import React, { useState, useEffect, useRef } from 'react';
import axios from 'axios';
import './App.css';
import { Chart, registerables } from 'chart.js';

// Register Chart.js components
Chart.register(...registerables);

function App() {
  const [inputText, setInputText] = useState('');
  const [imageUrl, setImageUrl] = useState('');
  const [loading, setLoading] = useState(false);
  const [metrics, setMetrics] = useState(null);
  const [style, setStyle] = useState('default');
  const [requestHistory, setRequestHistory] = useState([]);
  const [systemInfo, setSystemInfo] = useState({
    timestamp: new Date().toISOString(),
    region: 'us-west-2', // Simulated region
    availabilityZone: 'us-west-2a', // Simulated AZ
  });
  
  const latencyChartRef = useRef(null);
  const latencyChartInstance = useRef(null);
  const serviceDistributionChartRef = useRef(null);
  const serviceDistributionChartInstance = useRef(null);

  // Available styles
  const availableStyles = [
    { value: 'default', label: 'Default' },
    { value: 'bold', label: 'Bold' },
    { value: 'italic', label: 'Italic' },
    { value: 'fancy', label: 'Fancy' },
    { value: 'outline', label: 'Outline' },
    { value: 'digital', label: 'Digital' },
    { value: 'retro', label: 'Retro' },
    { value: 'colorful', label: 'Colorful' },
    { value: 'shadow', label: 'Shadow' },
    { value: 'glow', label: 'Glow' }
  ];

  useEffect(() => {
    // Update system info every 10 seconds
    const intervalId = setInterval(() => {
      setSystemInfo({
        timestamp: new Date().toISOString(),
        region: 'us-west-2',
        availabilityZone: 'us-west-2a',
      });
    }, 10000);

    return () => clearInterval(intervalId);
  }, []);

  useEffect(() => {
    if (metrics && latencyChartRef.current) {
      updateLatencyChart();
    }
    
    if (metrics && serviceDistributionChartRef.current) {
      updateServiceDistributionChart();
    }
  }, [metrics]);

  const updateLatencyChart = () => {
    if (latencyChartInstance.current) {
      latencyChartInstance.current.destroy();
    }

    const ctx = latencyChartRef.current.getContext('2d');
    
    // Group services by type for better visualization
    const serviceGroups = {
      letter: { times: [], count: 0, success: 0, failed: 0 },
      number: { times: [], count: 0, success: 0, failed: 0 },
      special: { times: [], count: 0, success: 0, failed: 0 },
      compositor: { times: [], count: 0, success: 0, failed: 0 }
    };
    
    // Process and group services
    metrics.serviceBreakdown.forEach(service => {
      if (service.name.includes('letter')) {
        serviceGroups.letter.times.push(service.time);
        serviceGroups.letter.count++;
        if (service.success) serviceGroups.letter.success++;
        else serviceGroups.letter.failed++;
      } else if (service.name.includes('number')) {
        serviceGroups.number.times.push(service.time);
        serviceGroups.number.count++;
        if (service.success) serviceGroups.number.success++;
        else serviceGroups.number.failed++;
      } else if (service.name.includes('special')) {
        serviceGroups.special.times.push(service.time);
        serviceGroups.special.count++;
        if (service.success) serviceGroups.special.success++;
        else serviceGroups.special.failed++;
      } else if (service.name.includes('compositor')) {
        serviceGroups.compositor.times.push(service.time);
        serviceGroups.compositor.count++;
        if (service.success) serviceGroups.compositor.success++;
        else serviceGroups.compositor.failed++;
      }
    });
    
    // Calculate average times for each group
    const labels = [];
    const avgTimes = [];
    const successRates = [];
    const colors = [];
    
    Object.entries(serviceGroups).forEach(([key, group]) => {
      if (group.count > 0) {
        const avgTime = group.times.reduce((sum, time) => sum + time, 0) / group.count;
        const successRate = group.count > 0 ? (group.success / group.count) * 100 : 0;
        
        labels.push(`${key} (${group.count})`);
        avgTimes.push(Math.round(avgTime));
        successRates.push(Math.round(successRate));
        
        // Color based on success rate
        if (successRate === 100) {
          colors.push('rgba(75, 192, 192, 0.6)'); // Green for 100% success
        } else if (successRate >= 80) {
          colors.push('rgba(255, 205, 86, 0.6)'); // Yellow for 80%+ success
        } else {
          colors.push('rgba(255, 99, 132, 0.6)'); // Red for lower success rates
        }
      }
    });
    
    latencyChartInstance.current = new Chart(ctx, {
      type: 'bar',
      data: {
        labels: labels,
        datasets: [{
          label: 'Avg. Latency (ms)',
          data: avgTimes,
          backgroundColor: colors,
          borderColor: colors.map(color => color.replace('0.6', '1')),
          borderWidth: 1,
          yAxisID: 'y'
        }, {
          label: 'Success Rate (%)',
          data: successRates,
          backgroundColor: 'rgba(153, 102, 255, 0.2)',
          borderColor: 'rgba(153, 102, 255, 1)',
          borderWidth: 1,
          type: 'line',
          yAxisID: 'y1'
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          title: {
            display: true,
            text: 'Service Group Performance'
          },
          tooltip: {
            callbacks: {
              afterLabel: function(context) {
                const index = context.dataIndex;
                const groupKey = labels[index].split(' ')[0];
                const group = serviceGroups[groupKey];
                return [
                  `Services: ${group.count}`,
                  `Success: ${group.success}`,
                  `Failed: ${group.failed}`,
                  `Success Rate: ${Math.round((group.success / group.count) * 100)}%`
                ];
              }
            }
          },
          legend: {
            position: 'top',
          }
        },
        scales: {
          y: {
            beginAtZero: true,
            position: 'left',
            title: {
              display: true,
              text: 'Latency (ms)'
            }
          },
          y1: {
            beginAtZero: true,
            position: 'right',
            max: 100,
            title: {
              display: true,
              text: 'Success Rate (%)'
            },
            grid: {
              drawOnChartArea: false
            }
          }
        }
      }
    });
  };

  const updateServiceDistributionChart = () => {
    if (serviceDistributionChartInstance.current) {
      serviceDistributionChartInstance.current.destroy();
    }

    const ctx = serviceDistributionChartRef.current.getContext('2d');
    
    // Count service types and their success/failure rates
    const serviceGroups = {
      letter: { count: 0, success: 0, failed: 0 },
      number: { count: 0, success: 0, failed: 0 },
      special: { count: 0, success: 0, failed: 0 },
      compositor: { count: 0, success: 0, failed: 0 }
    };
    
    metrics.serviceBreakdown.forEach(service => {
      if (service.name.includes('letter')) {
        serviceGroups.letter.count++;
        service.success ? serviceGroups.letter.success++ : serviceGroups.letter.failed++;
      } else if (service.name.includes('number')) {
        serviceGroups.number.count++;
        service.success ? serviceGroups.number.success++ : serviceGroups.number.failed++;
      } else if (service.name.includes('special')) {
        serviceGroups.special.count++;
        service.success ? serviceGroups.special.success++ : serviceGroups.special.failed++;
      } else if (service.name.includes('compositor')) {
        serviceGroups.compositor.count++;
        service.success ? serviceGroups.compositor.success++ : serviceGroups.compositor.failed++;
      }
    });
    
    // Prepare data for the chart
    const labels = [];
    const successData = [];
    const failureData = [];
    
    Object.entries(serviceGroups).forEach(([key, group]) => {
      if (group.count > 0) {
        labels.push(key.charAt(0).toUpperCase() + key.slice(1));
        successData.push(group.success);
        failureData.push(group.failed);
      }
    });
    
    serviceDistributionChartInstance.current = new Chart(ctx, {
      type: 'bar',
      data: {
        labels: labels,
        datasets: [
          {
            label: 'Success',
            data: successData,
            backgroundColor: 'rgba(75, 192, 192, 0.6)',
            borderColor: 'rgba(75, 192, 192, 1)',
            borderWidth: 1
          },
          {
            label: 'Failed',
            data: failureData,
            backgroundColor: 'rgba(255, 99, 132, 0.6)',
            borderColor: 'rgba(255, 99, 132, 1)',
            borderWidth: 1
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          title: {
            display: true,
            text: 'Service Success/Failure by Type'
          },
          tooltip: {
            callbacks: {
              afterTitle: function(tooltipItems) {
                const index = tooltipItems[0].dataIndex;
                const groupKey = labels[index].toLowerCase();
                const total = serviceGroups[groupKey].count;
                return `Total services: ${total}`;
              }
            }
          },
          legend: {
            position: 'top'
          }
        },
        scales: {
          y: {
            beginAtZero: true,
            stacked: true,
            title: {
              display: true,
              text: 'Number of Services'
            }
          },
          x: {
            stacked: true
          }
        }
      }
    });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    
    try {
      // Use environment variable for API URL or fallback to relative path
      const apiUrl = process.env.REACT_APP_API_URL || '';
      console.log('Using API URL:', apiUrl);
      
      const startTime = Date.now();
      const response = await axios.post(`${apiUrl}/generate`, { 
        text: inputText,
        style: style
      });
      const endTime = Date.now();
      const requestDuration = endTime - startTime;
      
      setImageUrl(response.data.imageUrl);
      setMetrics(response.data.metrics);
      
      // Add to request history
      const newRequest = {
        id: Date.now(),
        text: inputText,
        style: style,
        timestamp: new Date().toISOString(),
        duration: requestDuration,
        success: response.data.metrics.overallSuccess,
        serviceCount: response.data.metrics.servicesUsed
      };
      
      setRequestHistory(prevHistory => [newRequest, ...prevHistory].slice(0, 10));
      
    } catch (error) {
      console.error('Error generating image:', error);
      alert('Failed to generate image. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const calculateSuccessRate = () => {
    if (requestHistory.length === 0) return '0%';
    const successCount = requestHistory.filter(req => req.success).length;
    return `${Math.round((successCount / requestHistory.length) * 100)}%`;
  };

  const calculateAverageLatency = () => {
    if (requestHistory.length === 0) return '0 ms';
    const totalLatency = requestHistory.reduce((sum, req) => sum + req.duration, 0);
    return `${Math.round(totalLatency / requestHistory.length)} ms`;
  };

  return (
    <div className="App">
      <header className="App-header">
        <h1>Letter-by-Letter Image Generator</h1>
        <p>EKS AutoMode Demo Application</p>
      </header>
      
      <main>
        <div className="system-info">
          <div className="system-info-item">
            <span className="info-label">Region:</span>
            <span className="info-value">{systemInfo.region}</span>
          </div>
          <div className="system-info-item">
            <span className="info-label">AZ:</span>
            <span className="info-value">{systemInfo.availabilityZone}</span>
          </div>
          <div className="system-info-item">
            <span className="info-label">Time:</span>
            <span className="info-value">{new Date(systemInfo.timestamp).toLocaleTimeString()}</span>
          </div>
        </div>

        <form onSubmit={handleSubmit}>
          <div className="input-container">
            <div className="input-group">
              <input
                type="text"
                value={inputText}
                onChange={(e) => setInputText(e.target.value)}
                placeholder="Enter text to generate an image"
                required
              />
              <select 
                value={style} 
                onChange={(e) => setStyle(e.target.value)}
                className="style-selector"
              >
                {availableStyles.map(styleOption => (
                  <option key={styleOption.value} value={styleOption.value}>
                    {styleOption.label}
                  </option>
                ))}
              </select>
              <button type="submit" disabled={loading}>
                {loading ? 'Generating...' : 'Generate Image'}
              </button>
            </div>
          </div>
        </form>

        {loading && (
          <div className="loading-container">
            <div className="loading-spinner"></div>
            <p>Generating your image...</p>
          </div>
        )}

        <div className="content-grid">
          <div className="content-column">
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
                    <h3>Characters</h3>
                    <p>{metrics.charactersProcessed}</p>
                  </div>
                  <div className="metric-card">
                    <h3>Status</h3>
                    <p className={metrics.overallSuccess ? "success-status" : "error-status"}>
                      {metrics.overallSuccess ? "Success" : "Partial Failure"}
                    </p>
                  </div>
                </div>
                
                <div className="charts-container">
                  <div className="chart-wrapper">
                    <canvas ref={latencyChartRef}></canvas>
                  </div>
                  <div className="chart-wrapper">
                    <canvas ref={serviceDistributionChartRef}></canvas>
                  </div>
                </div>
                
                <h3>Service Details</h3>
                <div className="service-table-container">
                  <table className="service-table">
                    <thead>
                      <tr>
                        <th>Service</th>
                        <th>Latency</th>
                        <th>Status</th>
                      </tr>
                    </thead>
                    <tbody>
                      {metrics.serviceBreakdown && metrics.serviceBreakdown.map((service, index) => (
                        <tr key={index} className={service.success ? "" : "error-row"}>
                          <td>{service.name}</td>
                          <td>{service.time}ms</td>
                          <td>
                            <span className={`status-indicator ${service.success ? "success" : "error"}`}>
                              {service.success ? "Success" : "Failed"}
                            </span>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            )}
          </div>
          
          <div className="content-column sidebar">
            <div className="stats-container">
              <h2>System Statistics</h2>
              <div className="stats-grid">
                <div className="stat-card">
                  <h3>Success Rate</h3>
                  <p>{calculateSuccessRate()}</p>
                </div>
                <div className="stat-card">
                  <h3>Avg. Latency</h3>
                  <p>{calculateAverageLatency()}</p>
                </div>
                <div className="stat-card">
                  <h3>Requests</h3>
                  <p>{requestHistory.length}</p>
                </div>
              </div>
            </div>
            
            <div className="history-container">
              <h2>Request History</h2>
              <div className="history-list">
                {requestHistory.length === 0 ? (
                  <p className="no-history">No requests yet</p>
                ) : (
                  requestHistory.map(request => (
                    <div key={request.id} className="history-item">
                      <div className="history-header">
                        <span className="history-text">"{request.text}"</span>
                        <span className={`history-status ${request.success ? "success" : "error"}`}>
                          {request.success ? "✓" : "✗"}
                        </span>
                      </div>
                      <div className="history-details">
                        <span>Style: {request.style}</span>
                        <span>Time: {request.duration}ms</span>
                        <span>Services: {request.serviceCount}</span>
                      </div>
                      <div className="history-timestamp">
                        {new Date(request.timestamp).toLocaleTimeString()}
                      </div>
                    </div>
                  ))
                )}
              </div>
            </div>
          </div>
        </div>
      </main>
      
      <footer>
        <p>EKS AutoMode Demo - Letter-by-Letter Image Generator</p>
        <p className="version">Version 0.2.0</p>
      </footer>
    </div>
  );
}

export default App;
