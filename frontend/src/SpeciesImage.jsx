
import { useEffect, useState } from "react";
import "./SpeciesImage.css";

const API_BASE = import.meta.env.VITE_API_BASE_URL || "/api";

export default function SpeciesImage({ speciesName }) {
  const [photo, setPhoto] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;

    async function loadPhoto() {
      setLoading(true);
      setPhoto(null);

      try {
        const query = `${speciesName} fish underwater`;

        const response = await fetch(
          `${API_BASE}/unsplash/search?q=${encodeURIComponent(query)}`
        );

        if (!response.ok) {
          throw new Error("Photo request failed");
        }

        const data = await response.json();

        if (!cancelled) {
          setPhoto(data.photo || null);
        }
      } catch (error) {
        console.error("Unable to load species photo:", error.message);
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    }

    if (speciesName) {
      loadPhoto();
    } else {
      setLoading(false);
    }

    return () => {
      cancelled = true;
    };
  }, [speciesName]);

  if (loading) {
    return (
      <div className="species-image-placeholder">
        Loading photo…
      </div>
    );
  }

  if (!photo?.imageUrl) {
    return (
      <div className="species-image-placeholder">
        🐟
      </div>
    );
  }

  return (
    <div className="species-image-wrapper">
      <img
        className="species-image"
        src={photo.imageUrl}
        alt={photo.alt || speciesName}
        loading="lazy"
      />

      <p className="species-photo-credit">
        Photo by{" "}
        <a
          href={photo.photographerUrl}
          target="_blank"
          rel="noreferrer"
        >
          {photo.photographer}
        </a>{" "}
        on{" "}
        <a
          href={photo.unsplashUrl}
          target="_blank"
          rel="noreferrer"
        >
          Unsplash
        </a>
      </p>
    </div>
  );
}
