import { NextRequest, NextResponse } from "next/server"
import { db } from "@/lib/firebase-admin"
import { verifyAdminAuth } from "@/lib/middleware/admin-auth"

// GET - Retrieve all moreApps documents
export async function GET(request: NextRequest) {
  try {
    const adminContext = await verifyAdminAuth(request)
    if (!adminContext) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 })
    }

    const snapshot = await db.collection("moreApps").get()
    const apps = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }))

    return NextResponse.json(apps)
  } catch (error) {
    console.error("Error fetching moreApps:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}

// POST - Create a new moreApps document
export async function POST(request: NextRequest) {
  try {
    const adminContext = await verifyAdminAuth(request)
    if (!adminContext) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 })
    }

    const body = await request.json()

    if (!body.appName || !body.clickUrl || !body.imageUrl || !body.bundleId) {
      return NextResponse.json({ error: "All fields are required" }, { status: 400 })
    }

    const coins = Number(body.coins ?? 0)
    const rank = Number(body.rank ?? 1)
    const minBackgroundTime = Number(body.minBackgroundTime ?? 120)

    if (!Number.isFinite(coins) || coins <= 0) {
      return NextResponse.json({ error: "Coins must be a positive number" }, { status: 400 })
    }
    if (!Number.isFinite(minBackgroundTime) || minBackgroundTime < 0) {
      return NextResponse.json({ error: "minBackgroundTime must be a non-negative number" }, { status: 400 })
    }

    const appData = {
      coins,
      minBackgroundTime,
      appName: String(body.appName).trim(),
      clickUrl: String(body.clickUrl).trim(),
      imageUrl: String(body.imageUrl).trim(),
      active: body.active ?? true,
      bundleId: String(body.bundleId).trim(),
      rank: Number.isFinite(rank) && rank > 0 ? rank : 1,
    }

    const docRef = await db.collection("moreApps").add(appData)

    return NextResponse.json({
      success: true,
      id: docRef.id,
      message: "App created successfully",
    })
  } catch (error) {
    console.error("Error creating moreApps document:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}

// PUT - Update a moreApps document
export async function PUT(request: NextRequest) {
  try {
    const adminContext = await verifyAdminAuth(request)
    if (!adminContext) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 })
    }

    const body = await request.json()

    if (!body.id) {
      return NextResponse.json({ error: "App ID is required" }, { status: 400 })
    }

    const updateData: any = {}
    if (body.appName !== undefined) updateData.appName = String(body.appName).trim()
    if (body.clickUrl !== undefined) updateData.clickUrl = String(body.clickUrl).trim()
    if (body.imageUrl !== undefined) updateData.imageUrl = String(body.imageUrl).trim()
    if (body.bundleId !== undefined) updateData.bundleId = String(body.bundleId).trim()
    if (body.active !== undefined) updateData.active = !!body.active
    if (body.coins !== undefined) {
      const coins = Number(body.coins)
      if (!Number.isFinite(coins) || coins <= 0) {
        return NextResponse.json({ error: "Coins must be a positive number" }, { status: 400 })
      }
      updateData.coins = coins
    }
    if (body.minBackgroundTime !== undefined) {
      const t = Number(body.minBackgroundTime)
      if (!Number.isFinite(t) || t < 0) {
        return NextResponse.json({ error: "minBackgroundTime must be a non-negative number" }, { status: 400 })
      }
      updateData.minBackgroundTime = t
    }
    if (body.rank !== undefined) {
      const rank = Number(body.rank)
      if (!Number.isFinite(rank) || rank <= 0) {
        return NextResponse.json({ error: "Rank must be a positive number" }, { status: 400 })
      }
      updateData.rank = rank
    }

    await db.collection("moreApps").doc(body.id).update(updateData)

    return NextResponse.json({
      success: true,
      message: "App updated successfully",
    })
  } catch (error) {
    console.error("Error updating moreApps document:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}

// DELETE - Delete a moreApps document
export async function DELETE(request: NextRequest) {
  try {
    const adminContext = await verifyAdminAuth(request)
    if (!adminContext) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 })
    }

    const { searchParams } = new URL(request.url)
    const id = searchParams.get("id")

    if (!id) {
      return NextResponse.json({ error: "App ID is required" }, { status: 400 })
    }

    await db.collection("moreApps").doc(id).delete()

    return NextResponse.json({
      success: true,
      message: "App deleted successfully",
    })
  } catch (error) {
    console.error("Error deleting moreApps document:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}


