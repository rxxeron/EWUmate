import fs from 'fs';
import { execSync } from 'child_process';
import path from 'path';

const assets = [
    { name: 'icon.png', url: 'https://placehold.co/1024x1024/png?text=Icon' },
    { name: 'splash.png', url: 'https://placehold.co/1242x2436/png?text=Splash' },
    { name: 'adaptive-icon.png', url: 'https://placehold.co/1024x1024/png?text=Adaptive' },
    { name: 'favicon.png', url: 'https://placehold.co/48x48/png?text=Fav' },
];

const assetsDir = path.join(process.cwd(), 'assets');
if (!fs.existsSync(assetsDir)){
    fs.mkdirSync(assetsDir);
}

assets.forEach(asset => {
    const filePath = path.join(assetsDir, asset.name);
    console.log(`Downloading ${asset.name}...`);
    try {
        // Use -L to follow redirects (placehold.co usually redirects)
        // Use -k to ignore SSL if needed, but try without first.
        execSync(`curl -L "${asset.url}" -o "${filePath}"`);
    } catch (e) {
        console.error(`Failed to download ${asset.name}: ${e.message}`);
    }
});
