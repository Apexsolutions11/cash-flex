import { NextRequest, NextResponse } from "next/server"
import { db, admin } from "@/lib/firebase-admin"
import { verifyAdminAuth } from "@/lib/middleware/admin-auth"

// GET - Retrieve all follow tasks (socials)
export async function GET(request: NextRequest) {
  try {
    const adminContext = await verifyAdminAuth(request)
    if (!adminContext) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 })
    }

    const socialsSnapshot = await db.collection("socials").get()
    const socials = socialsSnapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }))

    return NextResponse.json(socials)
  } catch (error) {
    console.error("Error fetching follow tasks:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}

// POST - Create a new follow task
export async function POST(request: NextRequest) {
  try {
    const adminContext = await verifyAdminAuth(request)
    if (!adminContext) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 })
    }

    const body = await request.json()

    if (!body.tag || !body.type || !body.link || !body.name) {
      return NextResponse.json({ error: "All fields are required" }, { status: 400 })
    }

    const socialData: any = {
      tag: String(body.tag).trim(),
      type: String(body.type).trim(),
      link: String(body.link).trim(),
      name: String(body.name).trim(),
      active: body.active ?? true,
      coins: Number.isFinite(Number(body.coins)) ? Number(body.coins) : 10,
      minBackgroundTime: Number.isFinite(Number(body.minBackgroundTime))
        ? Number(body.minBackgroundTime)
        : 30,
    }

    // Add optional country and state fields if provided
    if (body.country !== undefined && body.country !== null && body.country !== '') {
      socialData.country = String(body.country).trim()
    }
    if (body.state !== undefined && body.state !== null && body.state !== '') {
      socialData.state = String(body.state).trim()
    }

    const docRef = await db.collection("socials").add(socialData)

    return NextResponse.json({
      success: true,
      id: docRef.id,
      message: "Follow task created successfully",
    })
  } catch (error) {
    console.error("Error creating follow task:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}

// PUT - Update a follow task
export async function PUT(request: NextRequest) {
  try {
    const adminContext = await verifyAdminAuth(request)
    if (!adminContext) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 })
    }

    const body = await request.json()

    if (!body.id) {
      return NextResponse.json({ error: "Task ID is required" }, { status: 400 })
    }

    const updateData: any = {}
    if (body.tag !== undefined) updateData.tag = String(body.tag).trim()
    if (body.type !== undefined) updateData.type = String(body.type).trim()
    if (body.link !== undefined) updateData.link = String(body.link).trim()
    if (body.name !== undefined) updateData.name = String(body.name).trim()
    if (body.active !== undefined) updateData.active = !!body.active
    if (body.coins !== undefined) {
      const coins = Number(body.coins)
      if (!Number.isFinite(coins) || coins < 0) {
        return NextResponse.json({ error: "coins must be a non-negative number" }, { status: 400 })
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
    
    // Handle optional country and state fields
    if (body.country !== undefined) {
      if (body.country === null || body.country === '') {
        // Remove country field if explicitly set to empty
        updateData.country = admin.firestore.FieldValue.delete()
      } else {
        updateData.country = String(body.country).trim()
      }
    }
    if (body.state !== undefined) {
      if (body.state === null || body.state === '') {
        // Remove state field if explicitly set to empty
        updateData.state = admin.firestore.FieldValue.delete()
      } else {
        updateData.state = String(body.state).trim()
      }
    }

    await db.collection("socials").doc(body.id).update(updateData)

    return NextResponse.json({
      success: true,
      message: "Follow task updated successfully",
    })
  } catch (error) {
    console.error("Error updating follow task:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}

// DELETE - Delete a follow task
export async function DELETE(request: NextRequest) {
  try {
    const adminContext = await verifyAdminAuth(request)
    if (!adminContext) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 })
    }

    const { searchParams } = new URL(request.url)
    const id = searchParams.get("id")

    if (!id) {
      return NextResponse.json({ error: "Task ID is required" }, { status: 400 })
    }

    await db.collection("socials").doc(id).delete()

    return NextResponse.json({
      success: true,
      message: "Follow task deleted successfully",
    })
  } catch (error) {
    console.error("Error deleting follow task:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}


