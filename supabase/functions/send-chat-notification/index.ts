import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { JWT } from 'npm:google-auth-library@9'

console.log("Edge Function 'send-chat-notification' iniciada (Versión FCM V1).");

serve(async (req) => {
  try {
    const payload = await req.json();
    const record = payload.record;

    if (!record || !record.offer_id || !record.sender_id) {
      return new Response(JSON.stringify({ error: "Payload inválido" }), { status: 400 });
    }

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // 1. Lógica relacional: Buscar la oferta
    const { data: offerData, error: offerError } = await supabaseClient
      .from('trade_offers')
      .select('offerer_id, post_id')
      .eq('id', record.offer_id)
      .single()

    if (offerError || !offerData) throw new Error("No se encontró la oferta de este chat.");

    // 2. Buscar al dueño del post
    const { data: tradeData, error: tradeError } = await supabaseClient
      .from('trades')
      .select('user_id')
      .eq('id', offerData.post_id)
      .single()

    if (tradeError || !tradeData) throw new Error("No se encontró la publicación de este chat.");

    // 3. Determinar el receptor
    const receiverId = record.sender_id === offerData.offerer_id
      ? tradeData.user_id
      : offerData.offerer_id;

    // 4. Buscar el FCM Token del receptor
    const { data: userData, error: userError } = await supabaseClient
      .from('users')
      .select('fcm_token')
      .eq('id', receiverId)
      .single()

    if (userError || !userData || !userData.fcm_token) {
      console.log(`El usuario receptor (${receiverId}) no tiene FCM Token instalado.`);
      return new Response(JSON.stringify({ message: "Usuario sin token FCM" }), { status: 200 });
    }

    // 5. Buscar el nombre y avatar de quien envía (El Sender)
    const { data: senderData } = await supabaseClient
      .from('users')
      .select('username, avatar_url')
      .eq('id', record.sender_id)
      .single()

    const senderName = senderData?.username || "Coleccionista";
    const senderAvatar = senderData?.avatar_url || "https://ui-avatars.com/api/?name=C";

    let messageBody = record.message;
    if (!messageBody && record.image_url) messageBody = "📷 Te envió una foto";
    if (!messageBody && record.audio_url) messageBody = "🎤 Te envió una nota de voz";

    // 6. OBTENER TOKEN DE GOOGLE (MAGIA V1)
    const serviceAccountStr = Deno.env.get('FIREBASE_SERVICE_ACCOUNT');
    if (!serviceAccountStr) throw new Error("No se encontró el secreto FIREBASE_SERVICE_ACCOUNT");

    const serviceAccount = JSON.parse(serviceAccountStr);
    const projectId = serviceAccount.project_id;

    const jwtClient = new JWT({
      email: serviceAccount.client_email,
      key: serviceAccount.private_key,
      scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
    });

    const tokens = await jwtClient.authorize();
    const accessToken = tokens.access_token;

    // 7. Construir Payload moderno con DATOS DINÁMICOS
    const fcmPayload = {
      message: {
        token: userData.fcm_token,
        notification: {
          title: `Nuevo mensaje de ${senderName}`,
          body: messageBody,
        },
        android: {
          notification: { sound: "default" }
        },
        apns: {
          payload: { aps: { sound: "default", badge: 1 } }
        },
        data: {
          type: "new_chat_message",
          // 👇 Usamos String() para que Firebase no elimine los datos en el viaje
          offer_id: String(record.offer_id),
          contact_id: String(record.sender_id),
          contact_name: String(senderName),
          contact_avatar: String(senderAvatar)
        }
      }
    };

    // 8. Enviar petición a la URL moderna de Google V1
    const response = await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${accessToken}`
      },
      body: JSON.stringify(fcmPayload)
    });

    const responseData = await response.json();
    console.log("¡Notificación enviada con éxito! Payload enviado:", fcmPayload.message.data);

    return new Response(JSON.stringify({ success: true, firebaseResponse: responseData }), {
      headers: { 'Content-Type': 'application/json' },
    })

  } catch (error) {
    console.error("Error crítico en la Edge Function:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { 'Content-Type': 'application/json' },
      status: 500
    })
  }
})