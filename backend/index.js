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
const ACCESS_TOKEN = process.env.MP_ACCESS_TOKEN?.trim();

if (!ACCESS_TOKEN) {
  console.error("❌ ERROR: La variable MP_ACCESS_TOKEN no está definida o es vacía.");
  process.exit(1);
}

console.log("✅ MP_ACCESS_TOKEN cargado correctamente");

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

    console.log("📦 Items enviados a Mercado Pago:", items);

    const response = await preferenceClient.create({ body: preferenceData });

    console.log("Preferencia creada:", response.init_point);

    res.json({
      init_point: response.init_point,
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
// 🔹 Crear pago con Yape
app.post("/crear-pago-yape", async (req, res) => {
  try {
    const { yapeToken, amount, description, payerEmail, payerPhone } = req.body;

    if (!yapeToken || !amount || !payerEmail || !payerPhone) {
      return res.status(400).json({ error: "Datos incompletos para Yape" });
    }

    const paymentData = {
      token: yapeToken,
      transaction_amount: amount,
      description,
      installments: 1,
      payment_method_id: "yape",
      payer: {
        email: payerEmail,
        phone: payerPhone,
      },
    };

    const response = await paymentClient.create({ body: paymentData });

    console.log("Pago Yape creado:", response.id);

    res.json({
      id: response.id,
      status: response.status,
      status_detail: response.status_detail,
    });
  } catch (err) {
    console.error("Error creando pago Yape:", err);
    res.status(500).json({ error: "No se pudo crear el pago Yape", detalle: err.message });
  }
});


// 🔹 Verificar pago (preference_id o payment_id)
app.get("/verificar/:id", async (req, res) => {
  const { id } = req.params;
  if (!id) return res.status(400).json({ error: "ID requerido" });

  try {
    // Primero intentamos buscar como payment_id
    try {
      const payment = await paymentClient.get({ id });
      return res.json({
        tipo: "payment",
        id: payment.id,
        status: payment.status,
        status_detail: payment.status_detail,
      });
    } catch (errPayment) {
      // Si no se encuentra, buscamos como preference_id
      const preference = await preferenceClient.get({ id });
      return res.json({
        tipo: "preference",
        id: preference.id,
        status: preference.status,
        init_point: preference.init_point,
        items: preference.items,
      });
    }
  } catch (err) {
    console.error("Error verificando ID:", err);
    res.status(500).json({
      error: "No se pudo verificar el ID",
      detalle: err.message,
    });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Servidor escuchando en puerto ${PORT}`));
