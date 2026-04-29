
const { createClient } = require('@supabase/supabase-js');
const s = createClient('https://jwygjihrbwxhehijldiz.supabase.co', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzExMDQxNzQsImV4cCI6MjA4NjY4MDE3NH0.zQc3dq53HBpMeN0rbJA9soF0oYhl7de1_sNnB_9JPoM');
const tables = ['courses_spring2026', 'courses_summer2026', 'completed_courses', 'enrollments'];
Promise.all(tables.map(t => s.from(t).select('*').eq('id', 'a2466748-0642-485a-b07e-64a816ca6913'))).then(results => {
  results.forEach((r, i) => {
    if (r.data && r.data.length > 0) {
      console.log('Found in', tables[i]);
      console.dir(r.data, {depth: null});
    }
  });
});

