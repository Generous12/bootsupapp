import express from "express";
import cors from "cors";
import mercadopagoPkg from "mercadopago";
import crypto from "crypto";

const { MercadoPagoConfig, Preference, Payment } = mercadopagoPkg;

// 🔹 Credenciales de Mercado Pago desde variables de entorno
const ACCESS_TOKEN = process.env.MP_ACCESS_TOKEN?.trim();
const MP_WEBHOOK_SECRET = process.env.MP_WEBHOOK_SECRET?.trim();

if (!ACCESS_TOKEN) {
  console.error("❌ ERROR: MP_ACCESS_TOKEN no definido.");
  process.exit(1);
}
if (!MP_WEBHOOK_SECRET) {
  console.error("❌ ERROR: MP_WEBHOOK_SECRET no definido.");
  process.exit(1);
}

console.log("✅ Variables de entorno cargadas correctamente.");

const client = new MercadoPagoConfig({ accessToken: ACCESS_TOKEN });
const preferenceClient = new Preference(client);
const paymentClient = new Payment(client);

const app = express();
app.use(cors());
app.use(express.json());

// 🔹 Crear preferencia
app.post("/crear-preferencia", async (req, res) => {
  try {
    const { items } = req.body;
    if (!items || !Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ error: "Items inválidos o vacíos" });
    }

    const preferenceData = {
      items,
      back_urls: {
        success: "https://tusitio.com/success",
        failure: "https://tusitio.com/failure",
        pending: "https://tusitio.com/pending",
      },
      auto_return: "approved",
      payment_methods: {
        installments: 1, // una sola cuota
      },
      notification_url:
        "https://adminvinosapp-production.up.railway.app/webhook?source_news=webhooks",
    };

    console.log("📦 Creando preferencia con:", preferenceData);

    const response = await preferenceClient.create({ body: preferenceData });

    res.json({
      init_point: response.init_point,
      preference_id: response.id,
    });
  } catch (error) {
    console.error("❌ Error creando preferencia:", error.response?.data || error);
    res.status(500).json({
      error: "Error creando la preferencia",
      detalle: error.response?.data?.message || error.message,
    });
  }
});

// 🔹 Endpoint para verificar pago
app.get("/verificar/:id", async (req, res) => {
  const { id } = req.params;
  if (!id) return res.status(400).json({ error: "ID requerido" });

  try {
    const payment = await paymentClient.get({ id });
    return res.json({
      tipo: "payment",
      id: payment.id,
      status: payment.status,
      status_detail: payment.status_detail,
    });
  } catch (err) {
    console.error("❌ Error verificando pago:", err);
    res.status(500).json({
      error: "No se pudo verificar el pago",
      detalle: err.message,
    });
  }
});

// 🔹 Webhook Mercado Pago con validación HMAC oficial
app.post("/webhook", express.raw({ type: "*/*" }), (req, res) => {
  try {
    const signature = req.headers["x-signature"];
    const requestId = req.headers["x-request-id"];
    const url = new URL(req.protocol + "://" + req.get("host") + req.originalUrl);
    const dataId = url.searchParams.get("data.id");
    const ts = signature
      ?.split(",")
      .find((s) => s.includes("ts"))
      ?.split("=")[1];
    const v1 = signature
      ?.split(",")
      .find((s) => s.includes("v1"))
      ?.split("=")[1];

    if (!signature || !ts || !v1 || !dataId || !requestId) {
      console.warn("⚠️ Webhook sin headers completos.");
      return res.status(401).send("Unauthorized");
    }

    // 🔑 Construir cadena para el HMAC
    const manifest = `id:${dataId};request-id:${requestId};ts:${ts};`;
    const computedHmac = crypto
      .createHmac("sha256", MP_WEBHOOK_SECRET)
      .update(manifest)
      .digest("hex");

    if (computedHmac !== v1) {
      console.warn("⚠️ Firma inválida");
      return res.status(401).send("Unauthorized");
    }

    const event = JSON.parse(req.body.toString());
    console.log("📩 Webhook recibido:", event);

    if (event.type === "payment") {
      console.log(`✅ Pago confirmado: ${event.data.id}`);
      // 🔹 Aquí actualizas tu base de datos
    }

    res.sendStatus(200);
  } catch (error) {
    console.error("❌ Error procesando webhook:", error);
    res.status(500).send("Webhook error");
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`🚀 Servidor escuchando en puerto ${PORT}`));
