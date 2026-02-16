const fs = require('fs');

const usersPath = './scripts/users_with_hashes.json';
const users = JSON.parse(fs.readFileSync(usersPath, 'utf8'));

const lines = users.map(u => JSON.stringify(u));
fs.writeFileSync('./scripts/users_with_hashes_nd.json', lines.join("\n"));
console.log("✅ Converted to NDJSON: ./scripts/users_with_hashes_nd.json");
