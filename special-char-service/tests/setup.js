// Global setup for tests
console.log('Starting Special Character Service functional tests...');
console.log(`Using service URL: ${process.env.TEST_SPECIAL_CHAR_SERVICE_URL || 'http://localhost:3005'}`);

// Increase timeout for all tests
jest.setTimeout(10000);
