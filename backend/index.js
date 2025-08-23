import express from "express";
import cors from "cors";
import mercadopagoPkg from "mercadopago";

const { MercadoPagoConfig, Preference, Payment } = mercadopagoPkg;

// 🔹 Credenciales Mercado Pago (producción) desde variables de entorno
const MP_CLIENT_ID = process.env.MP_CLIENT_ID;
const MP_CLIENT_SECRET = process.env.MP_CLIENT_SECRET;
const MP_REDIRECT_URI =
  process.env.MP_REDIRECT_URI ||
  "https://adminvinosapp-production.up.railway.app/oauth/callback";

// 🔹 Token de producción
const ACCESS_TOKEN = process.env.MP_ACCESS_TOKEN?.trim(); // ⚠️ Eliminamos espacios accidentales

if (!ACCESS_TOKEN) {
  console.error("❌ ERROR: La variable MP_ACCESS_TOKEN no está definida o es vacía.");
  process.exit(1); // Sale del servidor si no hay token
}

console.log("✅ MP_ACCESS_TOKEN cargado correctamente");

const client = new MercadoPagoConfig({
  accessToken: ACCESS_TOKEN,
});

const preferenceClient = new Preference(client);
const paymentClient = new Payment(client);

const app = express();
app.use(cors());
app.use(express.json());

// 🔹 Crear preferencia
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

    // 🔹 Log para depuración
    console.log("📦 Items enviados a Mercado Pago:", items);

    const response = await preferenceClient.create({ body: preferenceData });

    console.log("Preferencia creada:", response.init_point);

    res.json({
      init_point: response.init_point, // ⚠️ Link real de pago
      preference_id: response.id,
    });
  } catch (error) {
    console.error("Error creando la preferencia:", error.response?.data || error);
    res.status(500).json({
      error: "Error creando la preferencia",
      detalle: error.response?.data?.message || error.message || error,
    });
  }
});

// 🔹 Verificar pago manualmente
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
    res.status(500).json({
      error: "No se pudo verificar el pago",
      detalle: err.message,
    });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () =>
  console.log(`Servidor escuchando en puerto ${PORT}`)
);
