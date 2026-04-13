import { createClient } from 'npm:@supabase/supabase-js@2'
import admin from 'npm:firebase-admin@11.11.1'

// 1. Inicializamos Firebase Admin exactamente igual que en tu primera función
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
    const oldOffer = payload.old_record

    // 2. Filtro: Solo disparamos si el estado CAMBIÓ a 'accepted'
    if (!oldOffer || oldOffer.status === 'accepted' || offer.status !== 'accepted') {
      return new Response('No es una oferta recién aceptada, se ignora.', { status: 200 })
    }

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // 3. Buscamos el token del OFERTANTE (el que envió la oferta original)
    const { data: offerer } = await supabaseAdmin
      .from('users')
      .select('fcm_token')
      .eq('id', offer.offerer_id)
      .single()

    if (!offerer || !offerer.fcm_token) {
      return new Response(JSON.stringify({ message: 'El usuario no tiene token FCM' }), { status: 200 })
    }

    // 4. Armamos la notificación de Trato Aceptado
    const message = {
          token: offerer.fcm_token,
          notification: {
            title: '¡Trato Aceptado! 🎉',
            body: `Alguien acaba de aceptar tu oferta. ¡Toca aquí para ir a tus intercambios y abrir el chat!`,
          },
          data: {
            type: 'offer_accepted', // Esta es la etiqueta que lee tu NotificationService en Flutter
            offer_id: offer.id.toString()
          }
        }

    // 5. Enviamos usando el SDK que ya tienes configurado
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