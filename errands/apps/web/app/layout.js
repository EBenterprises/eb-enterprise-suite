import "./globals.css";

export const metadata = {
  title: "Errands®",
  description: "Errands® — coordinate errands, people, places and deliveries.",
  applicationName: "Errands®"
};

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
