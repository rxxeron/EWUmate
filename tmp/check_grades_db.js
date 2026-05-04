const { createClient } = require('@supabase/supabase-client');
require('dotenv').config({ path: 'd:/EWUmate/EWUmate_Clean/ewumate_v2/.env' });

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_ANON_KEY);

async function checkGrades() {
    const { data, error } = await supabase
        .from('grade_scale')
        .select('*');
    
    if (error) {
        console.error(error);
        return;
    }

    console.log('--- Grade Scales in Database ---');
    data.forEach(g => {
        console.log(`Policy: ${g.policy}, Grade: ${g.grade}, Point: ${g.point}`);
    });
}

checkGrades();
