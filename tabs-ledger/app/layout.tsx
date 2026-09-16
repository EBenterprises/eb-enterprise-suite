import "./globals.css";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Tabs® Ledger",
  description:
    "Local-first transaction and customer ledger platform"
};

export default function RootLayout({
  children
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
