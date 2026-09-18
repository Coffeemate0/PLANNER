import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

Deno.serve(async (req) => {
  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) return new Response(JSON.stringify({ error: 'Missing authorization' }), { status: 401, headers: {'content-type':'application/json'} });

    const url = Deno.env.get('SUPABASE_URL')!;
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!;
    const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

    const userClient = createClient(url, anonKey, { global: { headers: { Authorization: authHeader } } });
    const { data: { user }, error: userErr } = await userClient.auth.getUser();
    if (userErr || !user) return new Response(JSON.stringify({ error: 'Invalid session' }), { status: 401, headers: {'content-type':'application/json'} });

    const admin = createClient(url, serviceKey);
    const { error: dataErr } = await admin.rpc('delete_my_couple_data_as_admin', { p_user_id: user.id });
    if (dataErr) return new Response(JSON.stringify({ error: dataErr.message }), { status: 400, headers: {'content-type':'application/json'} });

    const { error: deleteErr } = await admin.auth.admin.deleteUser(user.id);
    if (deleteErr) return new Response(JSON.stringify({ error: deleteErr.message }), { status: 400, headers: {'content-type':'application/json'} });

    return new Response(JSON.stringify({ ok: true }), { status: 200, headers: {'content-type':'application/json'} });
  } catch (err) {
    return new Response(JSON.stringify({ error: err instanceof Error ? err.message : 'Unexpected error' }), { status: 500, headers: {'content-type':'application/json'} });
  }
});
