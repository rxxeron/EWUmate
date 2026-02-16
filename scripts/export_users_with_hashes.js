const admin = require('firebase-admin');
const fs = require('fs');

const FIREBASE_SERVICE_KEY_PATH = './service-accounts.json';
const OUTPUT_FILE = './scripts/users_with_hashes.json';

const serviceAccount = require(FIREBASE_SERVICE_KEY_PATH);
admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

async function exportUsers() {
    console.log("📥 Exporting ALL users with password hashes...");
    let users = [];
    let nextPageToken;

    try {
        do {
            const listUsersResult = await admin.auth().listUsers(1000, nextPageToken);
            listUsersResult.users.forEach((userRecord) => {
                const u = userRecord.toJSON();

                // Only include if password user
                const isPasswordUser = u.providerData.some(p => p.providerId === 'password');

                if (isPasswordUser && u.passwordHash && u.passwordSalt) {
                    users.push({
                        id: u.uid,
                        email: u.email,
                        email_verified: u.emailVerified,
                        // Supabase expects these fields for import via CLI/API
                        password_hash: u.passwordHash,
                        password_salt: u.passwordSalt,
                        // Additional meta
                        phone: u.phoneNumber,
                        created_at: u.metadata.creationTime,
                        updated_at: u.metadata.lastSignInTime,
                        custom_claims: u.customClaims,
                        app_metadata: {
                            provider: 'email',
                            providers: ['email']
                        },
                        user_metadata: {
                            displayName: u.displayName,
                            photoURL: u.photoUrl,
                            migratedFromFirebase: true
                        }
                    });
                }
            });
            nextPageToken = listUsersResult.pageToken;
        } while (nextPageToken);

        fs.writeFileSync(OUTPUT_FILE, JSON.stringify(users, null, 2));
        console.log(`✅ Exported ${users.length} password users to ${OUTPUT_FILE}`);
    } catch (e) {
        console.error("❌ Export failed:", e);
    }
}

exportUsers();
