import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";
// Import Google Auth for Deno/Node
import { UserRefreshClient } from "npm:google-auth-library";

// CORS Headers
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // 1. Authenticate the User
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    );

    const { data: { user }, error: userError } = await supabaseClient.auth.getUser();
    if (userError || !user) {
      throw new Error("Unauthorized");
    }

    // 2. Parse the Request Body
    const { fileName, fileSizeBytes, mimeType } = await req.json();
    if (!fileName || !fileSizeBytes) {
      throw new Error("Missing fileName or fileSizeBytes");
    }

    // 3. Find the Best Drive Account (Least used space that has enough capacity)
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    const { data: accounts, error: accountError } = await supabaseAdmin
      .from('drive_accounts')
      .select('*')
      .eq('is_active', true)
      .order('used_bytes', { ascending: true }); // Get least used first

    if (accountError || !accounts || accounts.length === 0) {
      throw new Error("No active drive accounts available");
    }

    let selectedAccount = null;
    for (const account of accounts) {
      if (account.total_capacity_bytes - account.used_bytes > fileSizeBytes) {
        selectedAccount = account;
        break;
      }
    }

    if (!selectedAccount) {
      throw new Error("Storage full on all nodes.");
    }

    // 4. Authenticate with Google API using Refresh Token!
    const oauth_json = typeof selectedAccount.service_account_json === 'string' 
      ? JSON.parse(selectedAccount.service_account_json) 
      : selectedAccount.service_account_json;

    const authClient = new UserRefreshClient({
      clientId: oauth_json.client_id,
      clientSecret: oauth_json.client_secret,
      refreshToken: oauth_json.refresh_token,
    });

    const accessTokenRes = await authClient.getAccessToken();
    const accessToken = accessTokenRes.token;

    // 5. Generate Resumable Upload URL from Google
    const driveUploadUrl = 'https://www.googleapis.com/upload/drive/v3/files?uploadType=resumable';
    
    const uploadRes = await fetch(driveUploadUrl, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
        'X-Upload-Content-Type': mimeType || 'application/octet-stream',
        'X-Upload-Content-Length': fileSizeBytes.toString()
      },
      body: JSON.stringify({
        name: fileName,
        parents: [selectedAccount.folder_id]
      })
    });

    if (!uploadRes.ok) {
      const errTxt = await uploadRes.text();
      throw new Error(`Google API Error: ${errTxt}`);
    }

    const resumableUrl = uploadRes.headers.get('location');

    if (!resumableUrl) {
      throw new Error("Failed to get resumable URL from Google");
    }

    // 6. Return the URL and the chosen Drive ID to Flutter
    return new Response(JSON.stringify({
      uploadUrl: resumableUrl,
      driveAccountId: selectedAccount.id,
      folderId: selectedAccount.folder_id
    }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    });

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    });
  }
});
