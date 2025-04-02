const express = require('express');
const axios = require('axios');
const router = express.Router();

// Environment variables for service URLs (with defaults for local development)
const LETTER_SERVICE_URL = process.env.LETTER_SERVICE_URL || 'http://letter-service';
const NUMBER_SERVICE_URL = process.env.NUMBER_SERVICE_URL || 'http://number-service';
const SPECIAL_CHAR_SERVICE_URL = process.env.SPECIAL_CHAR_SERVICE_URL || 'http://special-char-service';
const COMPOSITOR_SERVICE_URL = process.env.COMPOSITOR_SERVICE_URL || 'http://compositor';

// Helper function to determine which service to use for a character
function getServiceForCharacter(char) {
  if (/[A-Za-z]/.test(char)) {
    return {
      url: `${LETTER_SERVICE_URL}/generate`,
      type: 'letter'
    };
  } else if (/[0-9]/.test(char)) {
    return {
      url: `${NUMBER_SERVICE_URL}/generate`,
      type: 'number'
    };
  } else {
    return {
      url: `${SPECIAL_CHAR_SERVICE_URL}/generate`,
      type: 'special'
    };
  }
}

// Process text and generate images
router.post('/process', async (req, res) => {
  try {
    const { text, style = 'default' } = req.body;
    
    if (!text) {
      return res.status(400).json({ error: 'Text is required' });
    }
    
    // Process each character in parallel
    const characterPromises = Array.from(text).map(async (char, index) => {
      try {
        const service = getServiceForCharacter(char);
        
        // Call the appropriate service based on character type
        let payload;
        if (service.type === 'letter') {
          payload = { letter: char, style };
        } else if (service.type === 'number') {
          payload = { number: char, style };
        } else {
          payload = { character: char, style };
        }
        
        const response = await axios.post(service.url, payload, {
          responseType: 'arraybuffer',
          headers: {
            'Content-Type': 'application/json'
          }
        });
        
        // Return the image data and position
        return {
          position: index,
          imageData: response.data,
          character: char
        };
      } catch (error) {
        console.error(`Error processing character '${char}' at position ${index}:`, error.message);
        // Return a placeholder for failed characters
        return {
          position: index,
          error: true,
          character: char
        };
      }
    });
    
    // Wait for all character processing to complete
    const characterResults = await Promise.all(characterPromises);
    
    // Send the results to the compositor service
    const compositorResponse = await axios.post(`${COMPOSITOR_SERVICE_URL}/compose`, {
      images: characterResults,
      style
    }, {
      responseType: 'arraybuffer'
    });
    
    // Return the final composed image
    res.set('Content-Type', 'image/png');
    res.send(compositorResponse.data);
    
  } catch (error) {
    console.error('Error in process endpoint:', error.message);
    res.status(500).json({ error: 'Failed to process text' });
  }
});

module.exports = router;
