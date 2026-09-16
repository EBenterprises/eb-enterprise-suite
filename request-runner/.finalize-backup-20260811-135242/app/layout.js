import "./globals.css";

export const metadata = {
  title: "Request Runner®",
  description: "Real-time pickup and delivery request platform."
};

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}