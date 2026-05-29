import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Missing Authorization header' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    // 1. Get authenticated user details
    const token = authHeader.replace('Bearer ', '');
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);
    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Invalid user session' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // 2. Validate user_id inside the admin_users table (the source of truth)
    const { data: adminRecord, error: adminError } = await supabase
      .from('admin_users')
      .select('*')
      .eq('user_id', user.id)
      .maybeSingle();

    if (adminError || !adminRecord) {
      return new Response(JSON.stringify({ error: 'Access Denied: Admins only' }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // 3. Extract Azure configurations securely from Deno env secrets
    const azureUrl = Deno.env.get('AZURE_FUNCTION_URL') ?? 'https://ewumate-parser.azurewebsites.net';
    const azureKey = Deno.env.get('AZURE_ADMIN_SECRET_KEY') ?? Deno.env.get('AZURE_FUNCTION_KEY') ?? '';

    // 4. Parse payload
    const body = await req.json().catch(() => ({}));
    const { action, semester, preview, payload } = body;

    let targetUrl = '';
    let method = 'POST';
    let requestBody: any = null;

    if (action === 'portal_sync') {
      targetUrl = `${azureUrl}/api/scraper/portal_sync?code=${azureKey}&preview=${preview ?? 'true'}&semester=${semester ?? ''}`;
      method = 'GET';
    } else if (action === 'sync_api_courses') {
      targetUrl = `${azureUrl}/api/sync_api_courses?code=${azureKey}`;
      requestBody = JSON.stringify(payload);
    } else {
      targetUrl = `${azureUrl}/api/${action}?code=${azureKey}`;
      requestBody = JSON.stringify(payload);
    }

    // 5. Secure call to Azure in the cloud
    const azureRes = await fetch(targetUrl, {
      method,
      headers: {
        'Content-Type': 'application/json',
      },
      body: requestBody
    });

    const resultText = await azureRes.text();
    let resultJson;
    try {
      resultJson = JSON.parse(resultText);
    } catch {
      resultJson = { message: resultText };
    }

    return new Response(JSON.stringify(resultJson), {
      status: azureRes.status,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});
