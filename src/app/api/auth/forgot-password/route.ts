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
