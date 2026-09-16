import "./globals.css";

export const metadata = {
  title: "OMEGA® — Generative Intelligence Platform",
  description:
    "OMEGA® private generative intelligence and constraint-solving platform.",
  applicationName: "OMEGA®",
  authors: [{ name: "Easton Bodeux®" }],
  robots: "noindex,nofollow",
};

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
