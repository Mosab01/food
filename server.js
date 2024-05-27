const express = require("express");
const bodyParser = require("body-parser");
const cors = require("cors");
const mongoose = require("mongoose");
const path = require("path");

const app = express();
const port = 3000;

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(cors());
app.set("view engine", "ejs");
app.use(express.static(path.join(__dirname, "public")));

const mongoURI = "mongodb://localhost:27017/mealOrders"; // Replace with your MongoDB URI
mongoose.connect(mongoURI, { useNewUrlParser: true, useUnifiedTopology: true });

mongoose.connection.on("connected", () => {
  console.log("Connected to MongoDB");
});

mongoose.connection.on("error", (err) => {
  console.log("Error connecting to MongoDB:", err);
});

const mealSchema = new mongoose.Schema({
  name: String,
  price: Number,
  description: String,
});

const Meal = mongoose.model("Meals", mealSchema);

app.get("/meals", async (req, res) => {
  try {
    const meals = await Meal.find();
    res.json(meals);
  } catch (error) {
    res.status(500).send(error);
  }
});

const orderSchema = new mongoose.Schema({
  customerId: String,
  mealId: String,
  status: String,
  timestamp: String,
});

const Order = mongoose.model("Order", orderSchema);

app.post("/orders", async (req, res) => {
  const orderData = req.body;

  console.log("Order received:", orderData);

  const newOrder = new Order(orderData);
  try {
    await newOrder.save();
    res.status(200).json({ message: "Order placed successfully" });
  } catch (error) {
    console.error("Error saving order to MongoDB:", error);
    res.status(500).json({ message: "Failed to place order" });
  }
});

app.post("/updateOrder", async (req, res) => {
  const { orderId, status } = req.body;

  try {
    await Order.findByIdAndUpdate(orderId, { status: status });
    res.redirect("/orders");
  } catch (error) {
    console.error("Error updating order status:", error);
    res.status(500).json({ message: "Failed to update order status" });
  }
});

app.get("/orders", async (req, res) => {
  try {
    const allOrders = await Order.find();
    const ordersWithMeals = await Promise.all(
      allOrders.map(async (order) => {
        const meal = await Meal.findById(order.mealId);
        return {
          ...order._doc,
          meal: meal ? meal._doc : null, // Include meal details in the order
        };
      })
    );
    console.log(ordersWithMeals);
    res.render("orders", { orders: ordersWithMeals });
  } catch (error) {
    console.error("Error fetching orders from MongoDB:", error);
    res.status(500).json({ message: "Failed to fetch orders" });
  }
});

app.listen(port, () => {
  console.log(`Server is running on http://localhost:${port}`);
});
