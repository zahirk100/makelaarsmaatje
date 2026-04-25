import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Makelaarsmaatje",
  description: "Snellere lead-opvolging voor makelaars, zonder heen-en-weer mailen.",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="nl">
      <body>{children}</body>
    </html>
  );
}
