import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.47.10";
import { createHash } from "node:crypto";

serve(async (req) => {
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const supabase = createClient(
    requiredEnv("SUPABASE_URL"),
    requiredEnv("SUPABASE_SERVICE_ROLE_KEY"),
  );
  const merchantCode = requiredEnv("DUITKU_MERCHANT_CODE");
  const apiKey = requiredEnv("DUITKU_API_KEY");

  const payload = await parsePayload(req);
  const merchantOrderId = text(payload.merchantOrderId ?? payload.merchant_order_id);
  const duitkuReference = text(payload.reference ?? payload.duitkuReference);
  const amountText = text(payload.amount ?? payload.paymentAmount);
  const amount = Number(amountText);
  const resultCode = text(payload.resultCode ?? payload.statusCode);
  const receivedSignature = text(payload.signature).toLowerCase();
  const expectedSignature = md5(`${merchantCode}${amountText}${merchantOrderId}${apiKey}`);
  const signatureValid = receivedSignature === expectedSignature;

  const { data: payment } = await supabase
    .from("payments")
    .select("id, booking_id, owner_user_id, amount, owner_amount, status")
    .eq("merchant_order_id", merchantOrderId)
    .maybeSingle();

  const amountMatch = payment ? Number(payment.amount) === amount : false;

  await supabase.from("payment_events").insert({
    payment_id: payment?.id ?? null,
    merchant_order_id: merchantOrderId || null,
    duitku_reference: duitkuReference || null,
    event_type: resultCode || "callback",
    signature_valid: signatureValid,
    amount_match: amountMatch,
    raw_payload: payload,
  });

  if (!payment || !signatureValid || !amountMatch) {
    return json({ ok: false }, 400);
  }

  if (payment.status === "paid") {
    return json({ ok: true, idempotent: true });
  }

  const nextPaymentStatus = resultCode === "00" ? "paid" : "failed";
  const nextBookingStatus = resultCode === "00" ? "paid" : "pending_payment";

  const { data: updatedPayment, error: updateError } = await supabase
    .from("payments")
    .update({
      status: nextPaymentStatus,
      duitku_reference: duitkuReference || null,
      raw_callback: payload,
      paid_at: nextPaymentStatus === "paid" ? new Date().toISOString() : null,
    })
    .eq("id", payment.id)
    .neq("status", "paid")
    .select("id, booking_id, owner_user_id, owner_amount, status")
    .maybeSingle();

  if (updateError) {
    return json({ error: updateError.message }, 500);
  }

  if (!updatedPayment) {
    return json({ ok: true, idempotent: true });
  }

  await supabase
    .from("bookings")
    .update({ status: nextBookingStatus })
    .eq("id", updatedPayment.booking_id);

  if (nextPaymentStatus === "paid") {
    await supabase.rpc("increment_owner_pending_balance", {
      p_owner_user_id: updatedPayment.owner_user_id,
      p_amount: updatedPayment.owner_amount,
    });
  }

  return json({ ok: true });
});

async function parsePayload(req: Request): Promise<Record<string, unknown>> {
  const contentType = req.headers.get("content-type") ?? "";
  if (contentType.includes("application/json")) {
    return await req.json().catch(() => ({}));
  }
  const body = await req.text();
  const params = new URLSearchParams(body);
  return Object.fromEntries(params.entries());
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function requiredEnv(name: string) {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`${name} is not configured`);
  return value;
}

function text(value: unknown) {
  return value == null ? "" : String(value).trim();
}

function md5(input: string) {
  return createHash("md5").update(input).digest("hex");
}
