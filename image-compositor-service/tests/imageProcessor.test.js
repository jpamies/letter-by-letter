const { compositeImages, createTextImage, applyEffects } = require('../imageProcessor');

// Mock base64 image data for testing
const mockBase64Image = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

describe('Image Processor', () => {
  describe('compositeImages', () => {
    it('should throw an error if images array is empty', async () => {
      await expect(compositeImages([])).rejects.toThrow('Valid images array is required');
    });

    it('should throw an error if images array is not provided', async () => {
      await expect(compositeImages()).rejects.toThrow('Valid images array is required');
    });

    it('should return a base64 encoded image when given valid inputs', async () => {
      const result = await compositeImages([mockBase64Image, mockBase64Image]);
      expect(result).toMatch(/^data:image\/png;base64,/);
    });

    it('should respect custom options', async () => {
      const options = {
        spacing: 10,
        backgroundColor: '#ff0000',
        maxHeight: 100,
        padding: 5,
        format: 'jpeg'
      };
      
      const result = await compositeImages([mockBase64Image, mockBase64Image], options);
      expect(result).toMatch(/^data:image\/jpeg;base64,/);
    });
  });

  describe('createTextImage', () => {
    it('should throw an error if text is not provided', async () => {
      await expect(createTextImage()).rejects.toThrow();
    });

    it('should return a base64 encoded image when given valid text', async () => {
      const result = await createTextImage('Test');
      expect(result).toMatch(/^data:image\/png;base64,/);
    });

    it('should respect custom options', async () => {
      const options = {
        fontFamily: 'Courier',
        fontSize: 24,
        fontColor: '#ff0000',
        backgroundColor: '#0000ff',
        padding: 10,
        format: 'jpeg'
      };
      
      const result = await createTextImage('Test', options);
      expect(result).toMatch(/^data:image\/jpeg;base64,/);
    });
  });

  describe('applyEffects', () => {
    it('should throw an error if image is not provided', async () => {
      await expect(applyEffects()).rejects.toThrow();
    });

    it('should return a base64 encoded image when given valid inputs', async () => {
      const result = await applyEffects(mockBase64Image);
      expect(result).toMatch(/^data:image\/png;base64,/);
    });

    it('should apply grayscale effect when specified', async () => {
      const effects = {
        grayscale: true
      };
      
      const result = await applyEffects(mockBase64Image, effects);
      expect(result).toMatch(/^data:image\/png;base64,/);
    });

    it('should apply multiple effects when specified', async () => {
      const effects = {
        blur: 5,
        grayscale: true,
        rotate: 90,
        brightness: 1.2,
        contrast: 0.8,
        format: 'jpeg'
      };
      
      const result = await applyEffects(mockBase64Image, effects);
      expect(result).toMatch(/^data:image\/jpeg;base64,/);
    });
  });
});
