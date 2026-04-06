const fs = require('fs');
const txt = fs.readFileSync('c:\\Users\\Farzana Safa\\AppData\\Roaming\\Code\\User\\workspaceStorage\\9af9b6de3d9eed1e004128776b08ef06\\GitHub.copilot-chat\\chat-session-resources\\c7a17e37-ec94-4398-b31f-b82c81b0fcde\\call_MHw5N3VRZXlBOXBQMHlxMUttTmw__vscode-1775314789993\\content.txt', 'utf8');
const s = txt.split('tsx_content = \'\\'\\\'')[1].split('\\\'\\\'\'')[0];
fs.writeFileSync('src/pages/UserDetails.tsx', s);
