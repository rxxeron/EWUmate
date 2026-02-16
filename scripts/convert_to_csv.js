const fs = require('fs');

const usersPath = './scripts/users_with_hashes.json';
const users = JSON.parse(fs.readFileSync(usersPath, 'utf8'));

// CSV Header
const header = ["id", "email", "email_verified", "phone", "phone_verified", "password_hash", "password_salt", "created_at", "updated_at"];

const lines = [header.join(",")];

for (const u of users) {
    const row = [
        u.id,
        u.email,
        u.email_verified ? 'TRUE' : 'FALSE', // CSV usually wants boolean as TRUE/FALSE
        u.phone || '',
        u.phone ? 'TRUE' : 'FALSE',
        u.password_hash || '',
        u.password_salt || '',
        u.created_at || '',
        u.updated_at || ''
    ];
    lines.push(row.join(","));
}

fs.writeFileSync('./scripts/users_with_hashes.csv', lines.join("\n"));
console.log("✅ Converted to CSV: ./scripts/users_with_hashes.csv");
