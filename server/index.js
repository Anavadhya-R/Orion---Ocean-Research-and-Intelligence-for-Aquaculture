
const express = require("express");
const cors = require("cors");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const fs = require("fs/promises");
const path = require("path");
require("dotenv").config();

const app = express();
const PORT = process.env.PORT || 4000;
const JWT_SECRET = process.env.JWT_SECRET;

if (!JWT_SECRET || JWT_SECRET.length < 32) {
  console.error("Set JWT_SECRET to a random secret of at least 32 characters in .env");
  process.exit(1);
}

app.use(cors());
app.use(express.json({ limit: "20kb" }));
app.use("/api/data", require("./data-routes"));
app.use("/api/unsplash", require("./unsplash-routes"));

const usersFile = path.join(__dirname, "users.json");

async function readUsers() {
  return JSON.parse(await fs.readFile(usersFile, "utf8"));
}

async function writeUsers(users) {
  await fs.writeFile(usersFile, JSON.stringify(users, null, 2));
}

function publicUser(user) {
  return {
    id: user.id,
    name: user.name,
    email: user.email,
    role: user.role,
  };
}

function createToken(user) {
  return jwt.sign(
    { sub: user.id, role: user.role },
    JWT_SECRET,
    { expiresIn: "2h" }
  );
}

app.get("/api/auth/me", async (req, res) => {
  try {
    const authHeader = req.headers.authorization || "";
    const token = authHeader.startsWith("Bearer ")
      ? authHeader.slice(7)
      : "";

    if (!token) {
      return res.status(401).json({ message: "Authentication required." });
    }

    const payload = jwt.verify(token, JWT_SECRET);
    const users = await readUsers();
    const user = users.find((item) => item.id === payload.sub);

    if (!user) {
      return res.status(401).json({ message: "User account not found." });
    }

    return res.json({ user: publicUser(user) });
  } catch (error) {
    return res.status(401).json({ message: "Session expired or invalid." });
  }
});

app.get("/api/health", (_req, res) => {
  res.json({ status: "ok" });
});

app.post("/api/auth/register", async (req, res) => {
  try {
    const { name, email, password, role } = req.body || {};

    if (
      typeof name !== "string" ||
      !name.trim() ||
      typeof email !== "string" ||
      !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim()) ||
      typeof password !== "string" ||
      password.length < 8 ||
      password.length > 128
    ) {
      return res.status(400).json({
        message: "Enter your name, a valid email, and a password of at least 8 characters.",
      });
    }

    // Users cannot grant themselves administrator access.
    const allowedRoles = ["Farmer", "Researcher"];
    const selectedRole = allowedRoles.includes(role) ? role : "Researcher";
    const normalizedEmail = email.trim().toLowerCase();
    const users = await readUsers();

    if (users.some((user) => user.email === normalizedEmail)) {
      return res.status(409).json({
        message: "An account with this email already exists. Please sign in.",
      });
    }

    const user = {
      id: require("crypto").randomUUID(),
      name: name.trim(),
      email: normalizedEmail,
      passwordHash: await bcrypt.hash(password, 12),
      role: selectedRole,
    };

    users.push(user);
    await writeUsers(users);

    return res.status(201).json({
      token: createToken(user),
      user: publicUser(user),
    });
  } catch (error) {
    console.error("Registration error:", error);
    return res.status(500).json({ message: "Registration failed on the server." });
  }
});

app.post("/api/auth/login", async (req, res) => {
  try {
    const { email, password } = req.body || {};

    if (typeof email !== "string" || typeof password !== "string") {
      return res.status(400).json({
        message: "Email and password are required.",
      });
    }

    const users = await readUsers();
    const user = users.find(
      (item) => item.email === email.trim().toLowerCase()
    );

    if (!user || !(await bcrypt.compare(password, user.passwordHash))) {
      return res.status(401).json({
        message: "Invalid email or password. Register first if you do not have an account.",
      });
    }

    return res.json({
      token: createToken(user),
      user: publicUser(user),
    });
  } catch (error) {
    console.error("Login error:", error);
    return res.status(500).json({ message: "Login failed on the server." });
  }
});

app.post("/api/auth/logout", (_req, res) => {
  // The frontend must discard its token. This endpoint alone does not revoke JWTs.
  res.json({ message: "Logged out. Clear the client session." });
});

app.listen(PORT, () => {
  console.log(`Orion API running at http://localhost:${PORT}`);
});

