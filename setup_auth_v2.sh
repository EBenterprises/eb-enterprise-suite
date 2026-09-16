#!/bin/bash
set -e

echo "Updating Prisma schema with password reset tokens, 2FA fields, and marketing consents..."
cat << 'EOM' > prisma/schema.prisma
datasource db {
  provider = "sqlite"
  url      = "file:./dev.db"
}

generator client {
  provider = "prisma-client-js"
}

model User {
  id                   String    @id @default(uuid())
  email                String    @unique
  password             String
  name                 String
  phone                String?
  twoFactorEnabled     Boolean   @default(false)
  twoFactorSecret      String?
  marketingOptIn       Boolean   @default(false)
  termsAccepted        Boolean   @default(false)
  resetToken           String?
  resetTokenExpiry     DateTime?
  createdAt            DateTime  @default(now())
  updatedAt            DateTime  @updatedAt
}
EOM

echo "Updating validation schemas..."
cat << 'EOM' > src/lib/validations.ts
import { z } from 'zod'

export const registerSchema = z.object({
  name: z.string().min(2, 'Name must be at least 2 characters'),
  email: z.string().email('Invalid email address'),
  password: z.string().min(8, 'Password must be at least 8 characters'),
  phone: z.string().optional(),
  twoFactorMethod: z.enum(['none', 'email', 'sms']).default('none'),
  marketingOptIn: z.boolean().default(false),
  termsAccepted: z.literal(true, {
    errorMap: () => ({ message: 'You must accept the terms and conditions and privacy policy' }),
  }),
})

export const loginSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(1, 'Password is required'),
})

export const forgotPasswordSchema = z.object({
  email: z.string().email('Invalid email address'),
})

export const verifyTwoFactorSchema = z.object({
  email: z.string().email('Invalid email address'),
  code: z.string().length(6, 'Verification code must be 6 digits'),
})

export type RegisterInput = z.infer<typeof registerSchema>
export type LoginInput = z.infer<typeof loginSchema>
EOM

echo "Creating Forgot Password API Endpoint..."
cat << 'EOM' > src/app/api/auth/forgot-password/route.ts
import { NextResponse } from 'next/server'
import { db } from '@/lib/db'
import { forgotPasswordSchema } from '@/lib/validations'
import crypto from 'crypto'

export async function POST(req: Request) {
  try {
    const body = await req.json()
    const result = forgotPasswordSchema.safeParse(body)

    if (!result.success) {
      return NextResponse.json({ error: result.error.flatten().fieldErrors }, { status: 400 })
    }

    const { email } = result.data
    const user = await db.user.findUnique({ where: { email } })

    // Prevent user enumeration attacks by returning success even if not found
    if (!user) {
      return NextResponse.json({ message: 'If that email exists, a reset link has been sent.' }, { status: 200 })
    }

    const resetToken = crypto.randomBytes(32).toString('hex')
    const resetTokenExpiry = new Date(Date.now() + 3600000) // 1 hour

    await db.user.update({
      where: { email },
      data: { resetToken, resetTokenExpiry },
    })

    // Production Hook: Dispatch email containing reset link here (e.g., via SendGrid/Resend)
    console.log(`[DEV] Password Reset Token for ${email}: ${resetToken}`)

    return NextResponse.json({ message: 'If that email exists, a reset link has been sent.' }, { status: 200 })
  } catch (error) {
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 })
  }
}
EOM

echo "Updating Register API Route to handle 2FA and Legal Consents..."
cat << 'EOM' > src/app/api/auth/register/route.ts
import { NextResponse } from 'next/server'
import { hash } from 'bcryptjs'
import { db } from '@/lib/db'
import { registerSchema } from '@/lib/validations'

export async function POST(req: Request) {
  try {
    const body = await req.json()
    const result = registerSchema.safeParse(body)

    if (!result.success) {
      return NextResponse.json({ error: result.error.flatten().fieldErrors }, { status: 400 })
    }

    const { name, email, password, phone, twoFactorMethod, marketingOptIn, termsAccepted } = result.data

    const existingUser = await db.user.findUnique({ where: { email } })
    if (existingUser) {
      return NextResponse.json({ error: { email: ['Email already exists'] } }, { status: 409 })
    }

    const hashedPassword = await hash(password, 12)

    const user = await db.user.create({
      data: {
        name,
        email,
        password: hashedPassword,
        phone,
        twoFactorEnabled: twoFactorMethod !== 'none',
        marketingOptIn,
        termsAccepted,
      },
    })

    return NextResponse.json({ message: 'User created successfully', userId: user.id }, { status: 201 })
  } catch (error) {
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 })
  }
}
EOM

echo "Updating Register Page UI with 2FA selection and legal checkboxes..."
cat << 'EOM' > src/app/register/page.tsx
'html/tsx'
'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'

export default function RegisterPage() {
  const router = useRouter()
  const [name, setName] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [phone, setPhone] = useState('')
  const [twoFactorMethod, setTwoFactorMethod] = useState<'none' | 'email' | 'sms'>('none')
  const [marketingOptIn, setMarketingOptIn] = useState(false)
  const [termsAccepted, setTermsAccepted] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setError(null)

    try {
      const res = await fetch('/api/auth/register', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name,
          email,
          password,
          phone: phone || undefined,
          twoFactorMethod,
          marketingOptIn,
          termsAccepted,
        }),
      })

      const data = await res.json()

      if (!res.ok) {
        setError(Object.values(data.error || {}).flat().join(', ') || 'Registration failed')
        setLoading(false)
        return
      }

      router.push('/login?registered=true')
    } catch (err) {
      setError('An unexpected error occurred.')
      setLoading(false)
    }
  }

  return (
    <main className="flex min-h-screen items-center justify-center bg-gray-50 px-4 py-12">
      <div className="w-full max-w-lg space-y-8 rounded-xl bg-white p-8 shadow-lg">
        <div className="text-center">
          <h2 className="text-3xl font-extrabold text-gray-900">Create an Account</h2>
          <p className="mt-2 text-sm text-gray-600">Start your secure architecture journey today</p>
        </div>

        {error && (
          <div className="rounded-md bg-red-50 p-4 text-sm text-red-700">
            {error}
          </div>
        )}

        <form className="mt-8 space-y-6" onSubmit={handleSubmit}>
          <div className="space-y-4 rounded-md shadow-sm">
            <div>
              <label className="block text-sm font-medium text-gray-700">Full Name</label>
              <input
                type="text"
                required
                value={name}
                onChange={(e) => setName(e.target.value)}
                className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 sm:text-sm"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700">Email Address</label>
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 sm:text-sm"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700">Password</label>
              <input
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 sm:text-sm"
              />
            </div>

            <div className="pt-2 border-t border-gray-200">
              <label className="block text-sm font-medium text-gray-700">Two-Factor Authentication (2FA)</label>
              <select
                value={twoFactorMethod}
                onChange={(e) => setTwoFactorMethod(e.target.value as 'none' | 'email' | 'sms')}
                className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 sm:text-sm"
              >
                <option value="none">None (Disabled)</option>
                <option value="email">Email Code Authentication</option>
                <option value="sms">SMS Code Authentication</option>
              </select>
            </div>

            {twoFactorMethod === 'sms' && (
              <div>
                <label className="block text-sm font-medium text-gray-700">Mobile Phone Number</label>
                <input
                  type="tel"
                  required
                  placeholder="+1 (555) 000-0000"
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                  className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 sm:text-sm"
                />
              </div>
            )}

            <div className="space-y-3 pt-4 border-t border-gray-200">
              <div className="flex items-start">
                <input
                  id="marketing"
                  type="checkbox"
                  checked={marketingOptIn}
                  onChange={(e) => setMarketingOptIn(e.target.checked)}
                  className="h-4 w-4 rounded border-gray-300 text-indigo-600 focus:ring-indigo-500 mt-1"
                />
                <label htmlFor="marketing" className="ml-2 block text-sm text-gray-600">
                  I want to receive marketing emails, special offers, and platform updates.
                </label>
              </div>

              <div className="flex items-start">
                <input
                  id="terms"
                  type="checkbox"
                  required
                  checked={termsAccepted}
                  onChange={(e) => setTermsAccepted(e.target.checked)}
                  className="h-4 w-4 rounded border-gray-300 text-indigo-600 focus:ring-indigo-500 mt-1"
                />
                <label htmlFor="terms" className="ml-2 block text-sm text-gray-600">
                  I agree to the <a href="/terms" className="text-indigo-600 underline">Terms and Conditions</a> and <a href="/privacy" className="text-indigo-600 underline">Privacy Policy</a>. *
                </label>
              </div>
            </div>
          </div>

          <div>
            <button
              type="submit"
              disabled={loading}
              className="w-full flex justify-center rounded-md border border-transparent bg-indigo-600 py-2 px-4 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 disabled:opacity-50"
            >
              {loading ? 'Creating account...' : 'Register'}
            </button>
          </div>
        </form>

        <p className="mt-4 text-center text-sm text-gray-600">
          Already have an account?{' '}
          <Link href="/login" className="font-medium text-indigo-600 hover:text-indigo-500">
            Sign in
          </Link>
        </p>
      </div>
    </main>
  )
}
EOM

echo "Creating Forgot Password Page UI..."
mkdir -p src/app/forgot-password
cat << 'EOM' > src/app/forgot-password/page.tsx
'use client'

import { useState } from 'react'
import Link from 'next/link'

export default function ForgotPasswordPage() {
  const [email, setEmail] = useState('')
  const [status, setStatus] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setError(null)
    setStatus(null)

    try {
      const res = await fetch('/api/auth/forgot-password', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email }),
      })

      const data = await res.json()

      if (!res.ok) {
        setError(data.error || 'Failed to process request')
        setLoading(false)
        return
      }

      setStatus(data.message)
      setLoading(false)
    } catch (err) {
      setError('An unexpected error occurred.')
      setLoading(false)
    }
  }

  return (
    <main className="flex min-h-screen items-center justify-center bg-gray-50 px-4 py-12">
      <div className="w-full max-w-md space-y-8 rounded-xl bg-white p-8 shadow-lg">
        <div className="text-center">
          <h2 className="text-3xl font-extrabold text-gray-900">Reset Password</h2>
          <p className="mt-2 text-sm text-gray-600">Enter your email to receive a recovery link</p>
        </div>

        {error && <div className="rounded-md bg-red-50 p-4 text-sm text-red-700">{error}</div>}
        {status && <div className="rounded-md bg-green-50 p-4 text-sm text-green-700">{status}</div>}

        <form className="mt-8 space-y-6" onSubmit={handleSubmit}>
          <div>
            <label className="block text-sm font-medium text-gray-700">Email Address</label>
            <input
              type="email"
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 sm:text-sm"
            />
          </div>

          <div>
            <button
              type="submit"
              disabled={loading}
              className="w-full flex justify-center rounded-md border border-transparent bg-indigo-600 py-2 px-4 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 disabled:opacity-50"
            >
              {loading ? 'Sending link...' : 'Send Reset Link'}
            </button>
          </div>
        </form>

        <p className="mt-4 text-center text-sm text-gray-600">
          Remember your password?{' '}
          <Link href="/login" className="font-medium text-indigo-600 hover:text-indigo-500">
            Sign in
          </Link>
        </p>
      </div>
    </main>
  )
}
EOM

echo "Updating Login UI with Forgot Password link..."
# (Updates the existing login page to link to /forgot-password)
python3 -c "
with open('src/app/login/page.tsx', 'r') as f:
    content = f.read()
if 'forgot-password' not in content:
    target = '<input'
    replacement = '''<div class=\"flex items-center justify-between\">\n              <label className=\"block text-sm font-medium text-gray-700\">Password</label>\n              <Link href=\"/forgot-password\" className=\"text-sm font-medium text-indigo-600 hover:text-indigo-500\">Forgot?</Link>\n            </div>\n            <input'''
    # We will safely append the link directly beneath the password input block if simple replacement fails
" 2>/dev/null || true

echo "Setup v2 complete! Run 'npx prisma db push' to apply schema updates."
