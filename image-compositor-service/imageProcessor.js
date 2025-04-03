const sharp = require('sharp');
const { createCanvas, loadImage } = require('canvas');

/**
 * Processes and composites an array of base64 encoded images into a single image
 * @param {Array} images - Array of base64 encoded image strings
 * @param {Object} options - Composition options
 * @returns {Promise<string>} - Base64 encoded composite image
 */
async function compositeImages(images, options = {}) {
  try {
    const {
      spacing = 5,
      backgroundColor = '#ffffff',
      maxHeight = 200,
      padding = 20,
      format = 'png'
    } = options;

    // Validate input
    if (!images || !Array.isArray(images) || images.length === 0) {
      throw new Error('Valid images array is required');
    }

    // Process each image to get dimensions and buffers
    const processedImages = await Promise.all(
      images.map(async (imgStr) => {
        // Extract base64 data from data URL
        const base64Data = imgStr.replace(/^data:image\/\w+;base64,/, '');
        const buffer = Buffer.from(base64Data, 'base64');
        
        // Get image metadata
        const metadata = await sharp(buffer).metadata();
        
        // Resize if needed to maintain consistent height
        const resizedBuffer = await sharp(buffer)
          .resize({ height: Math.min(metadata.height, maxHeight), fit: 'contain' })
          .toBuffer();
          
        const resizedMetadata = await sharp(resizedBuffer).metadata();
        
        return {
          buffer: resizedBuffer,
          width: resizedMetadata.width,
          height: resizedMetadata.height
        };
      })
    );

    // Calculate total width and maximum height
    const totalWidth = processedImages.reduce(
      (sum, img, i) => sum + img.width + (i > 0 ? spacing : 0),
      0
    ) + (padding * 2);
    
    const maxImageHeight = Math.max(...processedImages.map(img => img.height));
    const totalHeight = maxImageHeight + (padding * 2);

    // Create a canvas for the composite image
    const canvas = createCanvas(totalWidth, totalHeight);
    const ctx = canvas.getContext('2d');

    // Fill background
    ctx.fillStyle = backgroundColor;
    ctx.fillRect(0, 0, totalWidth, totalHeight);

    // Draw each image on the canvas
    let currentX = padding;
    for (let i = 0; i < processedImages.length; i++) {
      const img = processedImages[i];
      const imgElement = await loadImage(img.buffer);
      
      // Center vertically
      const y = padding + (maxImageHeight - img.height) / 2;
      
      ctx.drawImage(imgElement, currentX, y, img.width, img.height);
      currentX += img.width + spacing;
    }

    // Convert canvas to buffer
    const buffer = canvas.toBuffer(`image/${format}`);
    
    // Convert buffer to base64
    const base64Image = buffer.toString('base64');
    return `data:image/${format};base64,${base64Image}`;
  } catch (error) {
    console.error('Error in image composition:', error);
    throw new Error(`Failed to composite images: ${error.message}`);
  }
}

/**
 * Creates a stylized text image using canvas
 * @param {string} text - Text to render
 * @param {Object} options - Styling options
 * @returns {Promise<string>} - Base64 encoded image
 */
async function createTextImage(text, options = {}) {
  try {
    const {
      fontFamily = 'Arial, sans-serif',
      fontSize = 48,
      fontColor = '#000000',
      backgroundColor = '#ffffff',
      padding = 20,
      format = 'png'
    } = options;

    // Create a canvas to measure text width
    const measureCanvas = createCanvas(1, 1);
    const measureCtx = measureCanvas.getContext('2d');
    measureCtx.font = `${fontSize}px ${fontFamily}`;
    
    const textMetrics = measureCtx.measureText(text);
    const textWidth = textMetrics.width;
    const textHeight = fontSize;
    
    // Create the actual canvas with proper dimensions
    const width = textWidth + (padding * 2);
    const height = textHeight + (padding * 2);
    
    const canvas = createCanvas(width, height);
    const ctx = canvas.getContext('2d');
    
    // Fill background
    ctx.fillStyle = backgroundColor;
    ctx.fillRect(0, 0, width, height);
    
    // Draw text
    ctx.font = `${fontSize}px ${fontFamily}`;
    ctx.fillStyle = fontColor;
    ctx.textBaseline = 'top';
    ctx.fillText(text, padding, padding);
    
    // Convert canvas to buffer
    const buffer = canvas.toBuffer(`image/${format}`);
    
    // Convert buffer to base64
    const base64Image = buffer.toString('base64');
    return `data:image/${format};base64,${base64Image}`;
  } catch (error) {
    console.error('Error creating text image:', error);
    throw new Error(`Failed to create text image: ${error.message}`);
  }
}

/**
 * Applies visual effects to an image
 * @param {string} imageData - Base64 encoded image
 * @param {Object} effects - Effects to apply
 * @returns {Promise<string>} - Base64 encoded processed image
 */
async function applyEffects(imageData, effects = {}) {
  try {
    const {
      blur = 0,
      grayscale = false,
      rotate = 0,
      brightness = 1,
      contrast = 1,
      format = 'png'
    } = effects;
    
    // Extract base64 data from data URL
    const base64Data = imageData.replace(/^data:image\/\w+;base64,/, '');
    const buffer = Buffer.from(base64Data, 'base64');
    
    // Apply effects using sharp
    let sharpInstance = sharp(buffer);
    
    if (blur > 0) {
      sharpInstance = sharpInstance.blur(blur);
    }
    
    if (grayscale) {
      sharpInstance = sharpInstance.grayscale();
    }
    
    if (rotate !== 0) {
      sharpInstance = sharpInstance.rotate(rotate);
    }
    
    if (brightness !== 1 || contrast !== 1) {
      sharpInstance = sharpInstance.modulate({
        brightness,
        contrast
      });
    }
    
    // Convert to specified format
    const outputBuffer = await sharpInstance
      .toFormat(format)
      .toBuffer();
    
    // Convert buffer to base64
    const outputBase64 = outputBuffer.toString('base64');
    return `data:image/${format};base64,${outputBase64}`;
  } catch (error) {
    console.error('Error applying effects:', error);
    throw new Error(`Failed to apply effects: ${error.message}`);
  }
}

module.exports = {
  compositeImages,
  createTextImage,
  applyEffects
};
