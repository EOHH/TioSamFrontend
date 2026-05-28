import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { JWT } from 'npm:google-auth-library@9'

serve(async (req) => {
  try {
    const payload = await req.json()
    const offer = payload.record
    const oldOffer = payload.old_record

    if (!oldOffer || oldOffer.status === 'accepted' || offer.status !== 'accepted') {
      return new Response('No es una oferta recién aceptada, se ignora.', { status: 200 })
    }

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // 🔥 NUEVO: Insertar en la tabla de notificaciones (Campanita)
    await supabaseAdmin
      .from('notifications')
      .insert({
        user_id: offer.offerer_id,
        title: '¡Trato Aceptado! 🎉',
        body: `Tu oferta fue aceptada. Toca aquí para ver los detalles.`,
        type: 'offer_accepted',
        data: { offer_id: offer.id }
      });

    const { data: offerer } = await supabaseAdmin
      .from('users')
      .select('fcm_token')
      .eq('id', offer.offerer_id)
      .single()

    if (!offerer || !offerer.fcm_token) {
      return new Response(JSON.stringify({ message: 'Notificación guardada. Usuario sin token FCM' }), { status: 200 })
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
        token: offerer.fcm_token,
        notification: {
          title: '¡Trato Aceptado! 🎉',
          body: `Tu oferta fue aceptada. Toca aquí para ver los detalles.`,
        },
        data: {
          type: 'offer_accepted',
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