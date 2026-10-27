const fs = require("fs/promises");
const path = require("path");
const crypto = require("crypto");
const bcrypt = require("bcryptjs");
require("dotenv").config({ path: path.join(__dirname, ".env") });

const usersFile = path.join(__dirname, "users.json");

async function main() {
  const email = process.env.ADMIN_EMAIL?.trim().toLowerCase();
  const password = process.env.ADMIN_PASSWORD;

  if (!process.env.JWT_SECRET || process.env.JWT_SECRET.length < 32) {
    throw new Error("Set a strong JWT_SECRET in server/.env first.");
  }

  if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    throw new Error("Set a valid ADMIN_EMAIL environment variable.");
  }

  if (typeof password !== "string" || password.length < 12 || password.length > 72) {
    throw new Error("ADMIN_PASSWORD must be 12–72 characters.");
  }

  let users = [];
  try {
    const raw = (await fs.readFile(usersFile, "utf8")).replace(/^\uFEFF/, "").trim();
    users = raw ? JSON.parse(raw) : [];
    if (!Array.isArray(users)) throw new Error("users.json must contain an array.");
  } catch (error) {
    if (error.code !== "ENOENT") throw error;
  }

  const existing = users.find((user) => user.email === email);
  const passwordHash = await bcrypt.hash(password, 12);

  if (existing) {
    existing.role = "Admin";
    existing.passwordHash = passwordHash;
    if (!existing.name) existing.name = "Orion Administrator";
    console.log("Existing account promoted to Admin and password updated.");
  } else {
    users.push({
      id: crypto.randomUUID(),
      name: "Orion Administrator",
      email,
      passwordHash,
      role: "Admin"
    });
    console.log("Admin account created.");
  }

  await fs.writeFile(usersFile, JSON.stringify(users, null, 2) + "\n", "utf8");
}

main().catch((error) => {
  console.error("Admin setup failed:", error.message);
  process.exitCode = 1;
});
