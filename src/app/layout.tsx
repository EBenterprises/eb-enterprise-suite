import './globals.css'
import type { Metadata } from 'react'

export const metadata: Metadata = {
  title: 'Secure Auth System',
  description: 'Production-ready login and registration',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  )
}
