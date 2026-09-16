import { NextResponse } from "next/server";
import {
  createVerifiedBackup,
  listBackups,
} from "@/lib/services/backup";

export const dynamic = "force-dynamic";

export async function GET() {
  try {
    return NextResponse.json({
      ok: true,
      backups: listBackups(),
    });
  } catch (error) {
    return NextResponse.json(
      {
        ok: false,
        error:
          error instanceof Error
            ? error.message
            : "Unable to list backups.",
      },
      { status: 500 }
    );
  }
}

export async function POST() {
  try {
    return NextResponse.json(createVerifiedBackup(), {
      status: 201,
    });
  } catch (error) {
    return NextResponse.json(
      {
        ok: false,
        error:
          error instanceof Error
            ? error.message
            : "Backup failed.",
      },
      { status: 500 }
    );
  }
}
