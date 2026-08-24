require('dotenv').config({ quiet: true });

const app = require('./src/app');

const port = process.env.PORT || 3000;

app.listen(port, () => {
  console.log(`BuildTrack Pro backend listening on port ${port}`);
});
