import { NextRequest, NextResponse } from "next/server"
import { db } from "@/lib/firebase-admin"
import { verifyAdminAuth } from "@/lib/middleware/admin-auth"

type LayoutType = "normal" | "google" | "international"

interface ComponentConfig {
  id: string
  enabled: boolean
  order: number
  type?: "component" | "heading"
  title?: string
}

interface PageLayoutConfig {
  homepage: ComponentConfig[]
  wallet: ComponentConfig[]
  invite: ComponentConfig[]
}

interface LayoutConfig {
  type: LayoutType
  homepage: ComponentConfig[]
  wallet: ComponentConfig[]
  invite: ComponentConfig[]
}

// GET - fetch all layouts
export async function GET(request: NextRequest) {
  try {
    const adminContext = await verifyAdminAuth(request)
    if (!adminContext) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 })
    }

    const layoutsDoc = await db.collection("admin").doc("layouts").get()

    if (!layoutsDoc.exists) {
      // Return default layouts
      return NextResponse.json({
        normal: null,
        google: null,
        international: null,
      })
    }

    const data = layoutsDoc.data()
    return NextResponse.json({
      normal: data?.normal || null,
      google: data?.google || null,
      international: data?.international || null,
    })
  } catch (error) {
    console.error("Error fetching layouts:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}

// POST - save all layouts
export async function POST(request: NextRequest) {
  try {
    const adminContext = await verifyAdminAuth(request)
    if (!adminContext) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 })
    }

    const body = await request.json() as Record<LayoutType, LayoutConfig>

    // Validate structure
    if (!body.normal || !body.google || !body.international) {
      return NextResponse.json(
        { error: "All three layouts (normal, google, international) are required" },
        { status: 400 }
      )
    }

    // Validate each layout has homepage, wallet and invite arrays
    for (const [layoutType, layout] of Object.entries(body)) {
      if (!layout.homepage || !Array.isArray(layout.homepage)) {
        return NextResponse.json(
          { error: `Layout ${layoutType} is missing homepage array` },
          { status: 400 }
        )
      }
      if (!layout.wallet || !Array.isArray(layout.wallet)) {
        return NextResponse.json(
          { error: `Layout ${layoutType} is missing wallet array` },
          { status: 400 }
        )
      }
      if (!layout.invite || !Array.isArray(layout.invite)) {
        return NextResponse.json(
          { error: `Layout ${layoutType} is missing invite array` },
          { status: 400 }
        )
      }
    }

    // Save to Firestore - store the full layout config including homepage, wallet, invite
    await db.collection("admin").doc("layouts").set({
      normal: {
        type: body.normal.type,
        homepage: body.normal.homepage,
        wallet: body.normal.wallet,
        invite: body.normal.invite,
      },
      google: {
        type: body.google.type,
        homepage: body.google.homepage,
        wallet: body.google.wallet,
        invite: body.google.invite,
      },
      international: {
        type: body.international.type,
        homepage: body.international.homepage,
        wallet: body.international.wallet,
        invite: body.international.invite,
      },
      updatedAt: new Date().toISOString(),
    }, { merge: false })

    return NextResponse.json({
      success: true,
      message: "Layouts saved successfully",
    })
  } catch (error) {
    console.error("Error saving layouts:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}

