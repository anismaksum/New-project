import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.47.10";
import { createHash } from "node:crypto";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const supabaseUrl = requiredEnv("SUPABASE_URL");
  const anonKey = requiredEnv("SUPABASE_ANON_KEY");
  const serviceRoleKey = requiredEnv("SUPABASE_SERVICE_ROLE_KEY");
  const merchantCode = requiredEnv("DUITKU_MERCHANT_CODE");
  const apiKey = requiredEnv("DUITKU_API_KEY");
  const duitkuBaseUrl = requiredEnv("DUITKU_BASE_URL").replace(/\/$/, "");
  const callbackUrl = requiredEnv("DUITKU_CALLBACK_URL");
  const returnUrl = requiredEnv("DUITKU_RETURN_URL");

  const authHeader = req.headers.get("Authorization") ?? "";
  const userSupabase = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });
  const adminSupabase = createClient(supabaseUrl, serviceRoleKey);

  const { booking_id, payment_method = "VC" } = await req.json();
  if (!booking_id) {
    return json({ error: "booking_id is required" }, 400);
  }

  const { data: booking, error: bookingError } = await userSupabase
    .from("bookings")
    .select("id, customer_user_id, owner_user_id, kost_id, rent_amount, status")
    .eq("id", booking_id)
    .single();

  if (bookingError || !booking) {
    return json({ error: "Booking not found" }, 404);
  }

  if (booking.status !== "pending_payment") {
    return json({ error: "Booking is not payable" }, 409);
  }

  const merchantOrderId = `KH-${booking.id}`;
  const amount = Number(booking.rent_amount);
  const platformFee = Math.round(amount * 0.03);
  const ownerAmount = amount - platformFee;

  const { data: existing } = await adminSupabase
    .from("payments")
    .select("id, status, payment_url, merchant_order_id")
    .eq("merchant_order_id", merchantOrderId)
    .maybeSingle();

  if (existing) {
    return json(existing);
  }

  const signature = sha256(`${merchantCode}${merchantOrderId}${amount}${apiKey}`);
  const payload = {
    merchantCode,
    paymentAmount: amount,
    paymentMethod: payment_method,
    merchantOrderId,
    productDetails: "Sewa kost KostHunt",
    callbackUrl,
    returnUrl,
    signature,
  };

  const duitkuResponse = await fetch(`${duitkuBaseUrl}/webapi/api/merchant/v2/inquiry`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });
  const duitkuBody = await duitkuResponse.json().catch(() => ({}));

  if (!duitkuResponse.ok) {
    return json({ error: "Duitku transaction failed", detail: duitkuBody }, 502);
  }

  const { data: payment, error: paymentError } = await adminSupabase
    .from("payments")
    .insert({
      booking_id: booking.id,
      customer_user_id: booking.customer_user_id,
      owner_user_id: booking.owner_user_id,
      kost_id: booking.kost_id,
      amount,
      platform_fee: platformFee,
      owner_amount: ownerAmount,
      merchant_order_id: merchantOrderId,
      duitku_reference: duitkuBody.reference ?? null,
      payment_method,
      payment_url: duitkuBody.paymentUrl ?? duitkuBody.payment_url ?? null,
      status: "waiting_payment",
    })
    .select("id, status, payment_url, merchant_order_id")
    .single();

  if (paymentError) {
    return json({ error: paymentError.message }, 500);
  }

  return json(payment);
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function requiredEnv(name: string) {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`${name} is not configured`);
  return value;
}

function sha256(input: string) {
  return createHash("sha256").update(input).digest("hex");
}
