const fs = require('fs');
const users = JSON.parse(fs.readFileSync('tmp/users.json', 'utf8')).users;
const user = users.find(u => u.email === 'rhrakibulhasan279@gmail.com');
if (user) {
    console.log(user.id);
} else {
    console.log('User not found');
}
