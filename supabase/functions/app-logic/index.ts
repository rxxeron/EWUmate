import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { action, data } = await req.json();

    let result = {};

    if (action === 'get_program_metadata') {
      result = {
        program_map: {
          'cse': 'B.Sc. in Computer Science & Engineering',
          'ice': 'B.Sc. in Information & Communications Engineering',
          'ete': 'B.Sc. in Electronic & Telecommunication Engineering',
          'eee': 'B.Sc. in Electrical & Electronic Engineering',
          'ce': 'B.Sc. in Civil Engineering',
          'pharm': 'Bachelor of Pharmacy (B.Pharm) Professional',
          'geb': 'B.Sc. in Genetic Engineering & Biotechnology',
          'dsa': 'B.Sc. in Data Science & Analytics',
          'math': 'B.Sc. (Hons) in Mathematics',
          'bba': 'Bachelor of Business Administration',
          'eco': 'B.S.S. (Hons) in Economics',
          'eng': 'B.A. (Hons) in English',
          'soc': 'B.S.S. (Hons) in Sociology',
          'islm': 'B.S.S. in Info. Studies & Library Management',
          'law': 'LL.B. (Hons)',
          'pphs': 'B.S.S. in Population and Public Health Sciences',
        }
      };
    } else if (action === 'calculate_scholarship') {
      const { cgpa, admitYear, admitTerm, programId } = data;
      
      // Scholarship Tier Logic
      const isNewRules = admitYear > 2026 || (admitYear === 2026 && admitTerm >= 1);
      let tier = "";
      
      if (isNewRules) {
        if (cgpa >= 3.95) tier = "100% Merit Scholarship";
        else if (cgpa >= 3.85) tier = "Dean’s List Scholarship";
        else if (cgpa >= 3.75) tier = "Medha Lalon Scholarship";
      } else {
        if (cgpa >= 3.90) tier = "100% Merit Scholarship";
        else if (cgpa >= 3.75) tier = "Dean’s List Scholarship";
        else if (cgpa >= 3.50) tier = "Medha Lalon Scholarship";
      }

      // Credit Requirement Logic
      const p = programId.toUpperCase();
      let requiredCredits = 30.0;
      
      const isUpto = (targetYear, targetTerm) => {
        if (admitYear < targetYear) return true;
        if (admitYear === targetYear && admitTerm <= targetTerm) return true;
        return false;
      };

      if (p.includes('CSE') || p.includes('ICE') || p.includes('EEE')) requiredCredits = 35.0;
      else if (p.includes('PHARM')) requiredCredits = 21.0; 
      else if (p.includes('MATHEMATICS') || p.includes('DSA')) requiredCredits = 33.0;
      else if (p.includes('INFORMATION STUDIES') || p.includes('ISLM')) requiredCredits = 30.0;
      else if (p.includes('ECONOMICS') || p.includes('ENGLISH') || p.includes('PPHS')) {
        requiredCredits = isUpto(2024, 1) ? 30.0 : 33.0;
      }
      else if (p.includes('LL.B') || p.includes('LAW')) requiredCredits = 21.0; 
      else if (p.includes('CE') || p.includes('CIVIL')) {
        requiredCredits = isUpto(2024, 1) ? 37.0 : 35.0;
      }
      else if (p.includes('BBA') || p.includes('BUSINESS') || p.includes('SOC')) {
        requiredCredits = isUpto(2024, 3) ? 30.0 : 33.0;
      }
      else if (p.includes('GEB') || p.includes('GENETIC')) {
        requiredCredits = isUpto(2025, 3) ? 33.0 : 35.0;
      }

      result = { tier, requiredCredits };
    } else if (action === 'get_scholarship_rule') {
      const { programId, admitYear, admitTerm } = data;
      
      // Engineering fallback
      const p = programId.toUpperCase();
      const isEng = p.includes('CSE') || p.includes('ICE') || p.includes('EEE') || 
                  p.includes('GEB') || p.includes('CE') || p.includes('PHARM');
      
      // New Rules Thresholds (Spring 2026+)
      const isNewRules = admitYear > 2026 || (admitYear === 2026 && admitTerm >= 1);
      
      let thresholds = {
        medha_lalon: isNewRules ? 3.75 : 3.50,
        deans_list: isNewRules ? 3.85 : 3.75,
        merit_100: isNewRules ? 3.95 : 3.90
      };

      let requiredCredits = isEng ? 35.0 : 30.0;
      
      // Program-specific exceptions
      if (p.includes('MATHEMATICS') || p.includes('DSA')) requiredCredits = 33.0;
      if (p.includes('PHARM') || p.includes('LL.B') || p.includes('LAW')) requiredCredits = 21.0;

      result = { thresholds, annualCreditsRequired: requiredCredits };
    } else if (action === 'get_program_metadata') {
      result = {
        'cse': 'B.Sc. in Computer Science & Engineering',
        'ice': 'B.Sc. in Information & Communications Engineering',
        'ete': 'B.Sc. in Electronic & Telecommunication Engineering',
        'eee': 'B.Sc. in Electrical & Electronic Engineering',
        'ce': 'B.Sc. in Civil Engineering',
        'pharm': 'Bachelor of Pharmacy (B.Pharm) Professional',
        'geb': 'B.Sc. in Genetic Engineering & Biotechnology',
        'dsa': 'B.Sc. in Data Science & Analytics',
        'math': 'B.Sc. (Hons) in Mathematics',
        'bba': 'Bachelor of Business Administration',
        'eco': 'B.S.S. (Hons) in Economics',
        'eng': 'B.A. (Hons) in English',
        'soc': 'B.S.S. (Hons) in Sociology',
        'islm': 'B.S.S. in Info. Studies & Library Management',
        'law': 'LL.B. (Hons)',
        'pphs': 'B.S.S. in Population and Public Health Sciences',
      };
    }

    return new Response(JSON.stringify(result), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
