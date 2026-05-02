import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { JWT } from 'npm:google-auth-library@9'

serve(async (req) => {
  try {
    const payload = await req.json()
    const offer = payload.record

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { data: trade } = await supabaseAdmin
      .from('trades')
      .select('user_id, offer_item')
      .eq('id', offer.post_id)
      .single()

    if (!trade) throw new Error("Publicación no encontrada")

    const { data: owner } = await supabaseAdmin
      .from('users')
      .select('fcm_token')
      .eq('id', trade.user_id)
      .single()

    if (!owner || !owner.fcm_token) {
      return new Response(JSON.stringify({ message: 'Usuario sin token FCM' }), { status: 200 })
    }

    // AUTH V1 MAGIA
    const serviceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT') || '{}')
    const jwtClient = new JWT({
      email: serviceAccount.client_email,
      key: serviceAccount.private_key,
      scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
    });
    const tokens = await jwtClient.authorize();

    const fcmPayload = {
      message: {
        token: owner.fcm_token,
        notification: {
          title: '¡Nueva Oferta Recibida! 🚀',
          body: `Alguien acaba de ofrecerte una carta por tu ${trade.offer_item}.`,
        },
        data: {
          type: 'new_offer',
          trade_id: String(offer.post_id),
          offer_id: String(offer.id)
        }
      }
    };

    await fetch(`https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${tokens.access_token}`
      },
      body: JSON.stringify(fcmPayload)
    });

    return new Response(JSON.stringify({ success: true }), { status: 200 })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500 })
  }
})