import { createClient } from 'npm:@supabase/supabase-js@2'
// CORRECCIÓN: Quitamos el "* as" para que Deno lo lea correctamente
import admin from 'npm:firebase-admin@11.11.1'

if (!admin.apps.length) {
  const serviceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT') || '{}')
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  })
}

Deno.serve(async (req) => {
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
      return new Response(JSON.stringify({ message: 'El usuario no tiene token FCM' }), { status: 200 })
    }

    const message = {
          token: owner.fcm_token,
          notification: {
            title: '¡Nueva Oferta Recibida! 🚀',
            body: `Alguien acaba de ofrecerte una carta por tu ${trade.offer_item}. ¡Abre la app para verla!`,
          },
          data: {
            type: 'new_offer',
            trade_id: offer.post_id.toString(), // ✅ CORREGIDO: Usamos el ID que viene en la oferta
            offer_id: offer.id.toString()
          }
        }

    await admin.messaging().send(message)

    return new Response(JSON.stringify({ success: true }), { 
      status: 200, 
      headers: { 'Content-Type': 'application/json' } 
    })

  } catch (error) {
    console.error(error)
    return new Response(JSON.stringify({ error: error.message }), { status: 500 })
  }
})