const axios = require('axios');

async function triggerSync() {
    try {
        const response = await axios.post(
            "https://jwygjihrbwxhehijldiz.supabase.co/functions/v1/sync-academic-stats",
            { userId: "374a09cd-c366-4eea-89cc-dbda99154c3e" },
            {
                headers: {
                    "Content-Type": "application/json",
                    "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzExMDQxNzQsImV4cCI6MjA4NjY4MDE3NH0.zQc3dq53HBpMeN0rbJA9soF0oYhl7de1_sNnB_9JPoM"
                }
            }
        );
        console.log('Sync response:', response.data);
    } catch (err) {
        console.error('Sync failed:', err.response ? err.response.data : err.message);
    }
}

triggerSync();
