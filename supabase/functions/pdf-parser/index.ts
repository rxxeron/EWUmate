/// <reference lib="deno.ns" />
/// <reference lib="deno.window" />

/**
 * PDF Parser Supabase Edge Function
 * Proxies PDF parsing to Azure Functions and saves results to database
 */

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface ParseRequest {
  type: 'exam' | 'course' | 'calendar' | 'advising';
  url?: string;
  base64Data?: string;
  filename?: string; // Extract semester from filename
  semesterId?: string; // Optional: override auto-detected semester
  saveToDatabase?: boolean; // Optional: skip DB save if false
  debug?: boolean;
}

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const startTime = Date.now();

  try {
    // Get environment variables
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const azureFunctionUrl = Deno.env.get("AZURE_FUNCTION_URL") || 
      "https://ewumate-parser.azurewebsites.net/api/parsepdf";
    const azureFunctionKey = Deno.env.get("AZURE_FUNCTION_KEY");

    if (!supabaseUrl || !supabaseKey) {
      throw new Error("Missing Supabase environment variables");
    }

    const supabase = createClient(supabaseUrl, supabaseKey, {
      auth: { persistSession: false },
    });

    // Parse request body
    const requestData: ParseRequest = await req.json();
    const { type, url, base64Data, filename, semesterId: providedSemesterId, saveToDatabase = true, debug } = requestData;

    console.log(`Request received - type: ${type}, filename: ${filename}, providedSemesterId: ${providedSemesterId}`);

    if (!type) {
      return new Response(
        JSON.stringify({ error: "Missing 'type' parameter" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Extract semester from filename (e.g., "Faculty List Spring 2026.pdf" -> "Spring2026")
    // Patterns: "Spring 2026", "Spring2026", "Summer 2026", "Fall 2026"
    let semesterId = providedSemesterId;
    let prettySemester = "";
    
    if (filename) {
      const match = filename.match(/(Spring|Summer|Fall)\s*(\d{4})/i);
      if (match) {
        const extractedSemId = `${match[1].charAt(0).toUpperCase()}${match[1].slice(1).toLowerCase()}${match[2]}`; // "Spring2026"
        prettySemester = `${match[1].charAt(0).toUpperCase()}${match[1].slice(1).toLowerCase()} ${match[2]}`; // "Spring 2026"
        
        // Use extracted semester if not provided
        if (!semesterId) {
          semesterId = extractedSemId;
        }
        
        console.log(`Extracted semester from filename: ${extractedSemId}, pretty: ${prettySemester}`);
      }
    }

    // If still no semester ID and not advising, use fallback
    if (!semesterId && type !== 'advising') {
      console.warn("Could not extract semester from filename, using UnknownSemester");
      semesterId = "UnknownSemester";
      prettySemester = "Unknown Semester";
    }
    
    // Ensure prettySemester is set even if semesterId was provided
    if (!prettySemester && semesterId && semesterId !== "UnknownSemester") {
      // Try to convert semesterId (e.g., "Spring2026") back to pretty format
      const match = semesterId.match(/(Spring|Summer|Fall)(\d{4})/i);
      if (match) {
        prettySemester = `${match[1].charAt(0).toUpperCase()}${match[1].slice(1).toLowerCase()} ${match[2]}`;
      }
    }
    
    console.log(`Using semesterId: ${semesterId}, prettySemester: ${prettySemester}`);


    // Call Azure Functions for parsing
    console.log(`Calling Azure Functions for ${type} parsing...`);
    const azureResponse = await fetch(`${azureFunctionUrl}?code=${azureFunctionKey}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        type,
        url,
        base64Data,
        semesterId
      })
    });

    if (!azureResponse.ok) {
      const errorText = await azureResponse.text();
      throw new Error(`Azure Function failed: ${azureResponse.status} - ${errorText}`);
    }

    const azureResult = await azureResponse.json();
    
    if (!azureResult.success) {
      throw new Error(`Parsing failed: ${azureResult.error || 'Unknown error'}`);
    }

    const parsedData = azureResult.data;
    const parseTime = Date.now() - startTime;
    
    console.log(`Parsed ${parsedData.length} items in ${parseTime}ms`);

    // Save to database if requested
    let insertResults = null;
    if (saveToDatabase && parsedData.length > 0) {
      console.log(`Saving ${parsedData.length} items to database...`);
      insertResults = await saveToDatabase_func(supabase, type, parsedData, semesterId, prettySemester, filename);
    }

    const totalTime = Date.now() - startTime;

    // Return successful result
    return new Response(
      JSON.stringify({
        success: true,
        type,
        count: parsedData.length,
        saved: insertResults ? insertResults.saved : 0,
        semesterId: semesterId,
        parseTime: parseTime,
        totalTime: totalTime,
        data: debug ? parsedData : undefined, // Only include data if debug mode
        insertResults: debug ? insertResults : undefined
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );

  } catch (error) {
    console.error("Parser error:", error);
    
    const errorMessage = error instanceof Error ? error.message : "Unknown error occurred";
    const errorStack = error instanceof Error ? error.stack : undefined;
    
    return new Response(
      JSON.stringify({
        success: false,
        error: errorMessage,
        stack: errorStack
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});

/**
 * Save parsed data to appropriate database tables
 */
async function saveToDatabase_func(supabase: any, type: string, data: any[], semesterId?: string, prettySemester?: string, filename?: string) {
  const results = { saved: 0, errors: 0, details: [] as any[] };

  try {
    switch (type) {
      case 'course': {
        const tableName = `courses_${semesterId}`;
        
        // Transform data to match DB schema
        const records = data.map(course => ({
          doc_id: course.docId,
          code: course.code,
          section: course.section,
          course_name: course.courseName || '',
          credits: course.credits || 0,
          capacity: course.capacity || '',
          type: course.type,
          semester: course.semester,
          sessions: course.sessions
        }));

        // Delete existing records for this semester
        const { error: deleteError } = await supabase
          .from(tableName)
          .delete()
          .neq('doc_id', '__DUMMY__'); // Delete all

        if (deleteError) {
          console.error('Delete error:', deleteError);
        }

        // Insert in batches (Supabase limit ~1000 per batch)
        const batchSize = 500;
        for (let i = 0; i < records.length; i += batchSize) {
          const batch = records.slice(i, i + batchSize);
          const { data: inserted, error } = await supabase
            .from(tableName)
            .upsert(batch, { onConflict: 'doc_id' });

          if (error) {
            console.error(`Batch ${i} error:`, error);
            results.errors += batch.length;
            results.details.push({ batch: i, error: error.message });
          } else {
            results.saved += batch.length;
          }
        }
        break;
      }

      case 'calendar': {
        const tableName = `calendar_${semesterId}`;
        
        const records = data.map(event => ({
          doc_id: event.docId,
          date: event.date,
          day: event.day,
          event: event.event,
          type: event.type,
          semester: event.semester
        }));

        // Delete existing
        await supabase.from(tableName).delete().neq('doc_id', '__DUMMY__');

        // Insert
        const { data: inserted, error } = await supabase
          .from(tableName)
          .upsert(records, { onConflict: 'doc_id' });

        if (error) {
          results.errors = records.length;
          results.details.push({ error: error.message });
        } else {
          results.saved = records.length;
        }

        // --- AUTO SEMESTER SWITCHING LOGIC ---
        // Try to extract current semester if prettySemester is empty
        // Look for semester mentions in the calendar data itself
        if (!prettySemester || prettySemester === "Unknown Semester") {
          console.log("Attempting to extract semester from calendar event data...");
          for (const evt of data.slice(0, 10)) { // Check first 10 events
            const eventText = `${evt.event || ''} ${evt.date || ''}`;
            const match = eventText.match(/(Spring|Summer|Fall)\s*(\d{4})/i);
            if (match) {
              prettySemester = `${match[1].charAt(0).toUpperCase()}${match[1].slice(1).toLowerCase()} ${match[2]}`;
              console.log(`Extracted semester from calendar data: ${prettySemester}`);
              break;
            }
          }
        }
        
        // Determine NEXT semester from current calendar semester
        // Spring -> Summer, Summer -> Fall, Fall -> Spring (next year)
        const getNextSemester = (currentSem: string): string | null => {
          const match = currentSem.match(/(Spring|Summer|Fall)\s*(\d{4})/i);
          if (!match) return null;
          
          const season = match[1].toLowerCase();
          const year = parseInt(match[2]);
          
          if (season === 'spring') return `Summer ${year}`;
          if (season === 'summer') return `Fall ${year}`;
          if (season === 'fall') return `Spring ${year + 1}`;
          
          return null;
        };
        
        const expectedNextSemester = getNextSemester(prettySemester || '');
        console.log(`Current calendar: ${prettySemester}, Expected next semester: ${expectedNextSemester}`);
        // Scan for "University Reopens for {ExpectedNextSemester}"
        let nextSemesterFound = null;
        let switchDate = null;
        
        if (expectedNextSemester) {
          for (const evt of data) {
            const content = evt.event || '';
            
            // Look for "University Reopens for {ExpectedNextSemester}"
            const reopenPattern = new RegExp(`University Reopens for\\s+${expectedNextSemester}`, 'i');
            if (reopenPattern.test(content)) {
              const dateText = evt.date || ''; // "May 12"
              
              // Extract year from expected semester
              const yearMatch = expectedNextSemester.match(/(\d{4})/);
              const year = yearMatch ? yearMatch[1] : new Date().getFullYear().toString();
              
              try {
                // Parse "May 12 2026" format
                const dt = new Date(`${dateText} ${year}`);
                if (!isNaN(dt.getTime())) {
                  nextSemesterFound = expectedNextSemester;
                  switchDate = dt.toISOString();
                  console.log(`✅ Scheduled Semester Switch: ${expectedNextSemester} on ${dt.toDateString()}`);
                  break;
                }
              } catch (ex) {
                console.error(`Error parsing switch date: ${dateText} ${year}`, ex);
              }
            }
          }
        }
        
        // Save semester switching configuration
        if (nextSemesterFound && switchDate) {
          await supabase.from('config').upsert({
            key: 'semester_switching',
            value: {
              nextSemester: nextSemesterFound,
              switchDate: switchDate,
              status: 'scheduled',
              identifiedAt: new Date().toISOString()
            },
            updated_at: new Date().toISOString()
          }, { onConflict: 'key' });
          
          // TODO: Schedule one-time cron job for the switch date
          // This would require calling a database function that uses pg_cron
          // For now, we save the config and can set up Edge Function scheduled trigger
          console.log(`📅 Semester switch scheduled for ${switchDate}`);
        }
        
        // Update current semester in config
        if (prettySemester) {
          await supabase.from('config').upsert({
            key: 'currentSemester',
            value: prettySemester,
            updated_at: new Date().toISOString()
          }, { onConflict: 'key' });
        }
        
        break;
      }

      case 'exam': {
        const tableName = `exams_${semesterId}`;
        
        // Note: exam schema needs to match the parsed data structure
        // Adjust field mapping based on actual parsed exam data structure
        const records = data.map(exam => ({
          course_code: exam.docId || exam.class_days, // May need adjustment
          exam_date: exam.exam_date,
          exam_time: exam.exam_day, // May need adjustment
          semester: exam.semester
        }));

        // Delete existing
        await supabase.from(tableName).delete().neq('course_code', '__DUMMY__');

        // Insert
        const { data: inserted, error } = await supabase
          .from(tableName)
          .upsert(records, { onConflict: 'course_code' });

        if (error) {
          results.errors = records.length;
          results.details.push({ error: error.message });
        } else {
          results.saved = records.length;
        }
        break;
      }

      case 'advising': {
        // Save to advising_schedules and advising_schedule_slots
        const sem_id = data[0]?.semester_id || `advising_${new Date().getTime()}`;
        
        // Insert schedule record
        const { error: schedError } = await supabase
          .from('advising_schedules')
          .upsert({ semester_id: sem_id, uploaded_at: new Date().toISOString() });

        if (schedError) {
          console.error('Advising schedule error:', schedError);
        }

        // Insert slots
        const slots = data.map(slot => ({
          slot_id: slot.slot_id || `slot_${Math.random().toString(36).substr(2, 9)}`,
          semester_id: sem_id,
          display_time: slot.display_time,
          start_time: slot.start_time,
          end_time: slot.end_time,
          min_credits: slot.min_credits || 0,
          max_credits: slot.max_credits || 999,
          schedule_id: slot.schedule_id || ''
        }));

        // Delete existing slots
        await supabase.from('advising_schedule_slots').delete().eq('semester_id', sem_id);

        // Insert new slots
        const { data: inserted, error } = await supabase
          .from('advising_schedule_slots')
          .upsert(slots, { onConflict: 'slot_id' });

        if (error) {
          results.errors = slots.length;
          results.details.push({ error: error.message });
        } else {
          results.saved = slots.length;
        }
        break;
      }
    }
  } catch (error) {
    console.error('Database save error:', error);
    results.errors = data.length;
    results.details.push({ error: error instanceof Error ? error.message : 'Unknown error' });
  }

  return results;
}
