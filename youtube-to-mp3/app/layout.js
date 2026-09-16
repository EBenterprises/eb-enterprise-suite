import "./globals.css";

export const metadata = {
  title: "YouTube to MP3®",
  description: "Authorized media conversion platform"
};

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
