
const express = require("express");
const router = express.Router();

router.get("/search", async (req, res) => {
  const query = String(req.query.q || "").trim();

  if (!query) {
    return res.status(400).json({ error: "Please provide a search query." });
  }

  const accessKey = process.env.UNSPLASH_ACCESS_KEY;

  if (!accessKey) {
    return res.status(500).json({
      error: "UNSPLASH_ACCESS_KEY is missing from the server .env file.",
    });
  }

  try {
    const url = new URL("https://api.unsplash.com/search/photos");
    url.searchParams.set("query", query);
    url.searchParams.set("per_page", "1");
    url.searchParams.set("orientation", "landscape");
    url.searchParams.set("content_filter", "high");

    const response = await fetch(url, {
      headers: {
        Authorization: `Client-ID ${accessKey}`,
      },
    });

    if (!response.ok) {
      return res.status(response.status).json({
        error: "Unsplash photo search failed.",
      });
    }

    const data = await response.json();
    const photo = data.results?.[0];

    if (!photo) {
      return res.json({ photo: null });
    }

    return res.json({
      photo: {
        id: photo.id,
        imageUrl: photo.urls?.regular,
        alt: photo.alt_description || query,
        photographer: photo.user?.name || "Unsplash photographer",
        photographerUrl: photo.user?.links?.html || "https://unsplash.com/",
        unsplashUrl: "https://unsplash.com/",
      },
    });
  } catch (error) {
    console.error("Unsplash error:", error.message);
    return res.status(500).json({
      error: "Unable to connect to Unsplash.",
    });
  }
});

module.exports = router;
