const fs = require('fs');
const path = require('path');

function processDir(dir) {
    const files = fs.readdirSync(dir);
    for (const file of files) {
        const fullPath = path.join(dir, file);
        if (fs.statSync(fullPath).isDirectory()) {
            processDir(fullPath);
        } else if (fullPath.endsWith('.dart')) {
            const content = fs.readFileSync(fullPath, 'utf8');
            try {
                // If it contains "Ã¢" or "Åž", it is likely corrupted
                if (content.includes('Ã') || content.includes('Å') || content.includes('ğŸ')) {
                    const buffer = Buffer.from(content, 'latin1');
                    const restoredUtf8 = buffer.toString('utf8');
                    fs.writeFileSync(fullPath, restoredUtf8, 'utf8');
                    console.log('Fixed:', fullPath);
                }
            } catch (e) {
                console.error('Failed on', fullPath, e);
            }
        }
    }
}

processDir('lib/presentation');
