import { NextRequest, NextResponse } from "next/server"
import { db } from "@/lib/firebase-admin"
import { verifyAdminAuth } from "@/lib/middleware/admin-auth"

type PromotionAppId = "app1" | "app2" | "app3" | "app4"

interface PromotionAppPayload {
  id: PromotionAppId
  enabled?: boolean
  photo?: string
  title?: string
  description?: string
  stars?: number
  coins?: number
  buttonText?: string
  playStoreUrl?: string
  tasks?: string[]
  minimumBackgroundTime?: number // in seconds
  badgeText?: string
  badgeVariant?: "none" | "default" | "popular" | "new" | "hot"
}

// GET - fetch admin/app1 and admin/app2
export async function GET(request: NextRequest) {
  try {
    const adminContext = await verifyAdminAuth(request)
    if (!adminContext) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 })
    }

    const app1Doc = await db.collection("admin").doc("app1").get()
    const app2Doc = await db.collection("admin").doc("app2").get()
    const app3Doc = await db.collection("admin").doc("app3").get()
    const app4Doc = await db.collection("admin").doc("app4").get()

    const app1 = app1Doc.exists ? app1Doc.data() : null
    const app2 = app2Doc.exists ? app2Doc.data() : null
    const app3 = app3Doc.exists ? app3Doc.data() : null
    const app4 = app4Doc.exists ? app4Doc.data() : null

    return NextResponse.json({
      app1,
      app2,
      app3,
      app4,
    })
  } catch (error) {
    console.error("Error fetching promotion apps:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}

// PUT - update admin/app1 or admin/app2
export async function PUT(request: NextRequest) {
  try {
    const adminContext = await verifyAdminAuth(request)
    if (!adminContext) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 })
    }

    const body = (await request.json()) as PromotionAppPayload

    if (!body.id || (body.id !== "app1" && body.id !== "app2" && body.id !== "app3" && body.id !== "app4")) {
      return NextResponse.json({ error: "Valid id (app1, app2, app3, or app4) is required" }, { status: 400 })
    }

    const updateData: any = {}

    if (body.enabled !== undefined) updateData.enabled = body.enabled
    if (body.photo !== undefined) updateData.photo = body.photo
    if (body.title !== undefined) updateData.title = body.title
    if (body.description !== undefined) updateData.description = body.description
    if (body.stars !== undefined) updateData.stars = body.stars
    if (body.coins !== undefined) updateData.coins = body.coins
    if (body.buttonText !== undefined) updateData.buttonText = body.buttonText
    if (body.playStoreUrl !== undefined) updateData.playStoreUrl = body.playStoreUrl
    if (body.tasks !== undefined) updateData.tasks = body.tasks
    if (body.minimumBackgroundTime !== undefined) updateData.minimumBackgroundTime = body.minimumBackgroundTime
    if (body.badgeText !== undefined) updateData.badgeText = body.badgeText
    if (body.badgeVariant !== undefined) updateData.badgeVariant = body.badgeVariant

    await db.collection("admin").doc(body.id).set(updateData, { merge: true })

    return NextResponse.json({
      success: true,
      message: `Promotion app ${body.id} updated successfully`,
    })
  } catch (error) {
    console.error("Error updating promotion app:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}


