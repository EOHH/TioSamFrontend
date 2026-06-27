import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

console.log("Iniciando Webhook de RevenueCat...");

serve(async (req) => {
  try {
    // 🛡️ PROTECCIÓN ANTI-HACKERS: Verificamos que la petición realmente venga de RevenueCat
    const authHeader = req.headers.get('Authorization');
    const webhookSecret = Deno.env.get('REVENUECAT_WEBHOOK_SECRET');

    if (!webhookSecret || authHeader !== `Bearer ${webhookSecret}`) {
      console.warn('⚠️ ALERTA DE SEGURIDAD: Intento de hackeo detectado (Firma inválida).');
      return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401 });
    }

    const body = await req.json();
    const event = body.event;

    // Solo nos importan las compras exitosas (no renovables como las Gemas)
    if (event.type === 'INITIAL_PURCHASE' || event.type === 'NON_RENEWING_PURCHASE') {
      const userId = event.app_user_id; // Debe coincidir con el ID de Supabase
      const productId = event.product_id;

      // 🔥 MAPA DE GEMAS: Asigna la cantidad de gemas según el ID del producto en Apple/Google
      // (Ajusta los nombres 'gems_100', etc., para que coincidan EXACTAMENTE con los IDs de tus productos en RevenueCat)
      let gemsToAdd = 0;
      if (productId.includes('100')) gemsToAdd = 100;
      else if (productId.includes('500')) gemsToAdd = 500;
      else if (productId.includes('1000')) gemsToAdd = 1000;
      // Añade más si tienes otros paquetes

      if (gemsToAdd > 0) {
        // Usamos SERVICE_ROLE_KEY para saltarnos el RLS y actuar como Dios
        const supabaseAdmin = createClient(
          Deno.env.get('SUPABASE_URL') ?? '',
          Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
        );

        // Llamamos a la función segura que creamos en SQL
        await supabaseAdmin.rpc('add_gems_secure', { 
          target_user_id: userId, 
          amount: gemsToAdd 
        });

        console.log(`¡Éxito! Se añadieron ${gemsToAdd} gemas al usuario ${userId}.`);
      }
    }

    return new Response(JSON.stringify({ success: true }), { status: 200 })
  } catch (error) {
    console.error("Error en Webhook:", error);
    return new Response(JSON.stringify({ error: error.message }), { status: 500 })
  }
})