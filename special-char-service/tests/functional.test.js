const axios = require('axios');
const fs = require('fs');
const path = require('path');

// Configuration
const SERVICE_URL = process.env.TEST_SPECIAL_CHAR_SERVICE_URL || 'http://localhost:3005';
const TEST_TIMEOUT = 10000; // 10 seconds

// Set longer timeout for all tests
jest.setTimeout(TEST_TIMEOUT);

describe('Special Character Service Functional Tests', () => {
  // Test the health endpoint
  describe('Health Check', () => {
    it('should return 200 OK with status', async () => {
      const response = await axios.get(`${SERVICE_URL}/health`);
      expect(response.status).toBe(200);
      expect(response.data).toHaveProperty('status', 'ok');
    });
  });

  // Test the generate endpoint with valid inputs
  describe('Generate Special Character Images', () => {
    // Test with a space character
    it('should generate an image for space character', async () => {
      const response = await axios.post(
        `${SERVICE_URL}/generate`,
        { character: ' ', style: 'default' },
        { responseType: 'arraybuffer' }
      );
      
      expect(response.status).toBe(200);
      expect(response.headers['content-type']).toBe('image/png');
      expect(response.data.length).toBeGreaterThan(0);
    });

    // Test with common special characters
    const specialChars = ['!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '-', '_', '+', '=', '{', '}', '[', ']', '|', '\\', ':', ';', '"', '\'', '<', '>', ',', '.', '?', '/'];
    
    specialChars.forEach(char => {
      it(`should generate an image for special character "${char}"`, async () => {
        const response = await axios.post(
          `${SERVICE_URL}/generate`,
          { character: char, style: 'default' },
          { responseType: 'arraybuffer' }
        );
        
        expect(response.status).toBe(200);
        expect(response.headers['content-type']).toBe('image/png');
        expect(response.data.length).toBeGreaterThan(0);
      });
    });

    // Test with different styles
    const styles = ['default', 'bold', 'colorful', 'shadow', 'glow'];
    
    styles.forEach(style => {
      it(`should generate an image with ${style} style`, async () => {
        const response = await axios.post(
          `${SERVICE_URL}/generate`,
          { character: '#', style },
          { responseType: 'arraybuffer' }
        );
        
        expect(response.status).toBe(200);
        expect(response.headers['content-type']).toBe('image/png');
        expect(response.data.length).toBeGreaterThan(0);
      });
    });
  });

  // Test error cases
  describe('Error Handling', () => {
    // Test with missing character
    it('should return 400 when character is missing', async () => {
      try {
        await axios.post(`${SERVICE_URL}/generate`, { style: 'default' });
        fail('Expected request to fail');
      } catch (error) {
        expect(error.response.status).toBe(400);
        expect(error.response.data).toHaveProperty('error');
      }
    });

    // Test with invalid character (letter)
    it('should return 400 when character is a letter', async () => {
      try {
        await axios.post(`${SERVICE_URL}/generate`, { character: 'A' });
        fail('Expected request to fail');
      } catch (error) {
        expect(error.response.status).toBe(400);
        expect(error.response.data).toHaveProperty('error');
      }
    });

    // Test with invalid character (number)
    it('should return 400 when character is a number', async () => {
      try {
        await axios.post(`${SERVICE_URL}/generate`, { character: '5' });
        fail('Expected request to fail');
      } catch (error) {
        expect(error.response.status).toBe(400);
        expect(error.response.data).toHaveProperty('error');
      }
    });

    // Test with multiple characters
    it('should return 400 when character has multiple characters', async () => {
      try {
        await axios.post(`${SERVICE_URL}/generate`, { character: '!@#' });
        fail('Expected request to fail');
      } catch (error) {
        expect(error.response.status).toBe(400);
        expect(error.response.data).toHaveProperty('error');
      }
    });
  });

  // Test performance
  describe('Performance', () => {
    it('should respond within acceptable time', async () => {
      const start = Date.now();
      
      await axios.post(
        `${SERVICE_URL}/generate`,
        { character: '!', style: 'default' },
        { responseType: 'arraybuffer' }
      );
      
      const duration = Date.now() - start;
      
      // Should respond within 500ms (plus artificial delay of 100-300ms)
      expect(duration).toBeLessThan(800);
    });
  });

  // Test concurrent requests
  describe('Concurrency', () => {
    it('should handle multiple concurrent requests', async () => {
      const chars = ['!', '@', '#', '$', '%', '^', '&', '*', '(', ')'];
      const promises = chars.map(char => 
        axios.post(
          `${SERVICE_URL}/generate`,
          { character: char, style: 'default' },
          { responseType: 'arraybuffer' }
        )
      );
      
      const results = await Promise.all(promises);
      
      results.forEach(response => {
        expect(response.status).toBe(200);
        expect(response.headers['content-type']).toBe('image/png');
        expect(response.data.length).toBeGreaterThan(0);
      });
    });
  });
});
