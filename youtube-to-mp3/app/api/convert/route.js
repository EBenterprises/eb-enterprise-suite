import { NextResponse } from "next/server";

function validUrl(value) {
  try {
    const url = new URL(value);

    return (
      url.protocol === "https:" &&
      (
        url.hostname === "youtube.com" ||
        url.hostname === "www.youtube.com" ||
        url.hostname === "youtu.be" ||
        url.hostname.endsWith(".youtube.com")
      )
    );
  } catch {
    return false;
  }
}

export async function POST(request) {
  try {
    const body = await request.json();
    const { url, quality = "192" } = body;

    if (!validUrl(url)) {
      return NextResponse.json(
        {
          error:
            "Enter a valid HTTPS YouTube URL for media you own or are authorized to download."
        },
        { status: 400 }
      );
    }

    const allowed = ["128", "192", "256", "320"];

    if (!allowed.includes(String(quality))) {
      return NextResponse.json(
        { error: "Unsupported audio quality." },
        { status: 400 }
      );
    }

    /*
      Conversion worker integration point.

      A production worker should:
      1. Verify authorization where applicable.
      2. Obtain the permitted source media.
      3. Extract audio with an appropriate licensed/authorized tool.
      4. Encode MP3.
      5. Store the temporary result.
      6. Return a short-lived download URL.
      7. Delete the temporary file automatically.

      This route deliberately does not implement unauthorized
      downloading of YouTube content.
    */

    return NextResponse.json({
      status: "queued",
      message:
        "Conversion infrastructure is ready. Connect an authorized media conversion worker to process this job.",
      quality: `${quality} kbps`
    });
  } catch {
    return NextResponse.json(
      { error: "Invalid conversion request." },
      { status: 400 }
    );
  }
}
