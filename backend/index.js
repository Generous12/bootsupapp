
import express from "express";
import cors from "cors";
import crypto from "crypto"; // 👈 para validar la firma
import mercadopagoPkg from "mercadopago";

const { MercadoPagoConfig, Preference, Payment } = mercadopagoPkg;

const client = new MercadoPagoConfig({
  accessToken: "TEST-1677503205510113-081212-25a602ecc6b38893a8e8eb8cb981af53-1292935930",
});

const preferenceClient = new Preference(client);
const paymentClient = new Payment(client);

const app = express();
app.use(cors());
app.use(express.json());

// 🔹 Guarda tu clave secreta como variable de entorno
const MP_WEBHOOK_SECRET = process.env.MP_WEBHOOK_SECRET || "3fb2004c68e32aec1dac03e8de4a816524a3d226d36e4484292131c2991b5859";

// Función para validar la firma del webhook
function verifySignature(req) {
  const xSignature = req.headers["x-signature"];
  const xRequestId = req.headers["x-request-id"];
  const query = req.originalUrl.split("?")[1] || "";

  if (!xSignature || !xRequestId) return false;

  const hmac = crypto.createHmac("sha256", MP_WEBHOOK_SECRET);
  hmac.update(`id:${xRequestId};query:${query}`);
  const expectedSignature = hmac.digest("hex");

  return xSignature.includes(expectedSignature);
}

// Crear preferencia
app.post("/crear-preferencia", async (req, res) => {
  try {
    const { items } = req.body;
    if (!items || !Array.isArray(items) || items.length === 0)
      return res.status(400).json({ error: "Items inválidos o vacíos" });

    const preferenceData = {
      items,
     back_urls: {
  success: "https://tusitio.com/success",
  failure: "https://tusitio.com/failure",
  pending: "https://tusitio.com/pending",
},
auto_return: "approved",
    };

    const response = await preferenceClient.create({ body: preferenceData });
  res.json({ 
  init_point: response.init_point,
  preference_id: response.id // ⚠️ importante
  });
  } catch (error) {
    console.error("Error creando la preferencia:", error);
    res.status(500).json({
      error: "Error creando la preferencia",
      detalle: error.message || error,
    });
  }
});

// Verificar pago manualmente
app.get("/verificar-pago/:id", async (req, res) => {
  try {
    const { id } = req.params;
    if (!id) return res.status(400).json({ error: "ID de pago requerido" });

    const payment = await paymentClient.get({ id });
    res.json({
      id: payment.id,
      status: payment.status,
      status_detail: payment.status_detail,
    });
  } catch (err) {
    console.error("Error verificando pago:", err);
    res.status(500).json({ error: "No se pudo verificar el pago", detalle: err.message });
  }
});

app.post("/webhook", async (req, res) => {
  try {
    // ✅ Validar antes de procesar
    if (!verifySignature(req)) {
      console.warn("⚠ Webhook rechazado: firma inválida");
      return res.sendStatus(401);
    }

    const evento = req.body;
    console.log("📩 Webhook válido recibido:", JSON.stringify(evento, null, 2));

    if (evento.type === "payment") {
      const paymentId = evento.data.id;

      const pago = await paymentClient.get({ id: paymentId });
      console.log(`💳 Pago ${paymentId} → Estado: ${pago.status}`);
      // Aquí actualizas tu base de datos según pago.status
    }

    res.sendStatus(200);
  } catch (error) {
    console.error("❌ Error procesando webhook:", error);
    res.sendStatus(500);
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Servidor escuchando en puerto ${PORT}`));
