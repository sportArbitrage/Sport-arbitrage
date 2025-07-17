const fs = require('fs');
const path = require('path');

// Ensure the directories exist
if (!fs.existsSync('src')) {
    fs.mkdirSync('src');
}

if (!fs.existsSync(path.join('src', 'scrapers'))) {
    fs.mkdirSync(path.join('src', 'scrapers'));
}

// Create app.js
const appJsContent = `const express = require('express');
const { scrapeBet9ja } = require('./scrapers/bet9jaScraper');

const app = express();
const port = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.send('Hello World! The sports arbitrage bot is running.');
});

app.listen(port, () => {
  console.log(\`Server is running on port \${port}\`);
  scrapeBet9ja();
});
`;

// Create bet9jaScraper.js
const scraperJsContent = `const axios = require('axios');
const cheerio = require('cheerio');

const BET9JA_SOCCER_URL = 'https://web.bet9ja.com/sport/soccer';

async function fetchFootballData(url) {
  try {
    const response = await axios.get(url);
    const html = response.data;
    return html;
  } catch (error) {
    console.error(\`Error fetching data from \${url}:\`, error);
    return null;
  }
}

async function scrapeBet9ja() {
  console.log('Scraping Bet9ja...');
  const html = await fetchFootballData(BET9JA_SOCCER_URL);
  if (html) {
    console.log('Successfully fetched HTML from Bet9ja.');
    // Next step is to parse the HTML and extract the odds.
    // For now, we just log a success message.
  }
}

module.exports = {
  scrapeBet9ja,
};
`;

// Write the files
fs.writeFileSync(path.join('src', 'app.js'), appJsContent);
fs.writeFileSync(path.join('src', 'scrapers', 'bet9jaScraper.js'), scraperJsContent);

console.log('Files created successfully!');