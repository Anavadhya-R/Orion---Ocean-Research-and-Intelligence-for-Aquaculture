
import { useState } from "react";
import "./auth.css";

const API_BASE = import.meta.env.VITE_API_BASE_URL || "/api";

export default function Auth({ onAuthenticated }) {
  const [mode, setMode] = useState("login");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [name, setName] = useState("");
  const [role, setRole] = useState("Researcher");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  async function handleSubmit(event) {
    event.preventDefault();
    setError("");
    setLoading(true);

    try {
      const endpoint =
        mode === "login" ? "/auth/login" : "/auth/register";

      const response = await fetch(`${API_BASE}${endpoint}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(
          mode === "login"
            ? { email, password }
            : { name, email, password, role }
        ),
      });

      const data = await response.json().catch(() => ({}));

      if (!response.ok) {
        throw new Error(
          data.message || data.detail ||
          "Authentication failed. Please try again."
        );
      }

      if (!data.token || !data.user) {
        throw new Error(
          "The server response is missing the login token or user details."
        );
      }

      sessionStorage.setItem("orion_token", data.token);
      sessionStorage.setItem("orion_user", JSON.stringify(data.user));
      onAuthenticated(data.user);
    } catch (err) {
      setError(
        err.message.includes("Failed to fetch")
          ? "Cannot reach the authentication server. The backend must be running."
          : err.message
      );
    } finally {
      setLoading(false);
    }
  }

  return (
    <main className="auth-screen">
      <section className="auth-art">
        <a className="auth-brand" href="#orion">
          <span className="auth-logo">O</span>
          <span>
            <strong>orion<span>.</span></strong>
            <small>OCEAN INTELLIGENCE</small>
          </span>
        </a>

        <div className="auth-art-copy">
          <span className="auth-eyebrow">OCEAN RESEARCH PLATFORM</span>
          <h1>A clearer view of our oceans.</h1>
          <p>
            Bring marine biodiversity, ocean conditions and
            aquaculture research together in one thoughtful workspace.
          </p>
          <div className="auth-orbit" aria-hidden="true">
            <span className="auth-orb auth-orb-one" />
            <span className="auth-orb auth-orb-two" />
            <span className="auth-orb auth-orb-three" />
            <span className="auth-wave">≈</span>
          </div>
        </div>

        <p className="auth-footnote">
          ORION · Explore. Understand. Sustain.
        </p>
      </section>

      <section className="auth-form-side">
        <form className="auth-form" onSubmit={handleSubmit}>
          <span className="auth-eyebrow">
            YOUR RESEARCH WORKSPACE
          </span>

          <h2>
            {mode === "login" ? "Welcome back" : "Create your account"}
          </h2>

          <p className="auth-description">
            {mode === "login"
              ? "Sign in to continue to your Orion workspace."
              : "Register as a farmer or researcher to get started."}
          </p>

          {mode === "register" && (
            <>
              <label>
                Full name
                <input
                  autoComplete="name"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  required
                  placeholder="Your full name"
                />
              </label>

              <label>
                Account role
                <select
                  value={role}
                  onChange={(e) => setRole(e.target.value)}
                >
                  <option value="Farmer">Farmer</option>
                  <option value="Researcher">Researcher</option>
                </select>
                <small>
                  Admin accounts must be provisioned securely by an administrator.
                </small>
              </label>
            </>
          )}

          <label>
            Email address
            <input
              type="email"
              autoComplete="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              placeholder="you@example.com"
            />
          </label>

          <label>
            Password
            <input
              type="password"
              autoComplete={
                mode === "login" ? "current-password" : "new-password"
              }
              minLength={8}
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              placeholder="At least 8 characters"
            />
          </label>

          {error && (
            <p className="auth-error" role="alert">{error}</p>
          )}

          <button className="auth-submit" type="submit" disabled={loading}>
            {loading
              ? "Please wait..."
              : mode === "login"
                ? "Sign in to Orion →"
                : "Create account →"}
          </button>

          <p className="auth-switch">
            {mode === "login"
              ? "New to Orion?"
              : "Already have an account?"}
            {" "}
            <button
              type="button"
              onClick={() => {
                setMode(mode === "login" ? "register" : "login");
                setError("");
              }}
            >
              {mode === "login" ? "Create an account" : "Sign in"}
            </button>
          </p>

          <p className="auth-security-note">
            Your account and access permissions must be verified by
            the Orion backend.
          </p>
        </form>
      </section>
    </main>
  );
}
